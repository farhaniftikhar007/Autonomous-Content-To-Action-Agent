from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
import models
from database import get_db
import json

# For Phase 2 Parsers
import pandas as pd
from bs4 import BeautifulSoup
import requests
# pyrefly: ignore [missing-import]
import PyPDF2
from io import BytesIO
from websocket.logger import log_event

router = APIRouter()

class UrlRequest(BaseModel):
    url: str

class LiveFeedRequest(BaseModel):
    source: str
    content: str
    credibility: float = 0.5

@router.post("/upload/pdf")
async def upload_pdf(file: UploadFile = File(...), db: Session = Depends(get_db)):
    if not file.filename.endswith('.pdf'):
        raise HTTPException(status_code=400, detail="Must be a PDF file")
    
    log_event(f"Analyzing PDF report feed: '{file.filename}'", level="info", source="analysis")
    content = await file.read()
    try:
        pdf_reader = PyPDF2.PdfReader(BytesIO(content))
        text_content = ""
        for page in pdf_reader.pages:
            text_content += page.extract_text() + "\n"
            
        ingested = models.IngestedData(
            source_type="pdf",
            source_name=file.filename,
            raw_content=text_content,
            parsed_data=json.dumps({"pages": len(pdf_reader.pages)})
        )
        db.add(ingested)
        db.commit()
        db.refresh(ingested)
        
        log_event(
            message=f"Ingested PDF: '{file.filename}' ({len(pdf_reader.pages)} pages). Starting System Context scan...",
            level="success",
            source="analysis"
        )
        return {"status": "success", "id": ingested.id, "extracted_length": len(text_content)}
    except Exception as e:
        log_event(f"PDF parsing failure on '{file.filename}': {str(e)}", level="error", source="analysis")
        raise HTTPException(status_code=500, detail=f"PDF parsing failed: {str(e)}")

@router.post("/upload/csv")
async def upload_csv(file: UploadFile = File(...), db: Session = Depends(get_db)):
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Must be a CSV file")
        
    log_event(f"Analyzing CSV inventory feed: '{file.filename}'", level="info", source="analysis")
    content = await file.read()
    try:
        df = pd.read_csv(BytesIO(content))
        parsed_json = df.to_json(orient="records")
        
        # Clear out old inventory items and unresolved alerts to ensure a clean swap of datasets
        db.query(models.InventoryItem).delete()
        db.query(models.Alert).filter(models.Alert.is_resolved == False).delete()
        db.commit()
        
        ingested = models.IngestedData(
            source_type="csv",
            source_name=file.filename,
            raw_content="CSV Data",
            parsed_data=parsed_json
        )
        db.add(ingested)
        
        # Helper to get value using any common alias in a case-insensitive way
        def get_value(row, keys_list, default):
            for k in keys_list:
                if k in row:
                    val = row[k]
                    if pd.isna(val) or val is None:
                        return default
                    return val
            # Try case-insensitive lookup
            row_keys_lower = {str(rk).lower().strip(): rk for rk in row.keys()}
            for k in keys_list:
                k_lower = k.lower().strip()
                if k_lower in row_keys_lower:
                    val = row[row_keys_lower[k_lower]]
                    if pd.isna(val) or val is None:
                        return default
                    return val
            return default
        
        # Populate/update InventoryItem table dynamically
        for index, row in df.iterrows():
            row_dict = row.to_dict()
            sku = str(get_value(row_dict, ['sku', 'product_id', 'product_code', 'id', 'item_code'], '')).strip()
            if not sku or sku == 'nan' or sku.lower() == 'none':
                continue
            name = str(get_value(row_dict, ['name', 'product_name', 'title', 'item_name'], 'Unknown Item')).strip()
            
            try:
                qty = int(float(get_value(row_dict, ['quantity', 'qty', 'stock', 'quantity_in_stock', 'units'], 0)))
            except:
                qty = 0
            try:
                reorder = int(float(get_value(row_dict, ['reorder_level', 'reorder', 'reorder_point', 'min_stock'], 10)))
            except:
                reorder = 10
            try:
                sup_id = int(float(get_value(row_dict, ['supplier_id', 'supplier', 'supplier_code'], 1)))
            except:
                sup_id = 1
            try:
                sales = int(float(get_value(row_dict, ['sales_last_7_days', 'sales', 'sales_7_days', 'weekly_sales'], 0)))
            except:
                sales = 0
            try:
                comp = int(float(get_value(row_dict, ['complaints', 'complaint_count', 'issues'], 0)))
            except:
                comp = 0
                
            updated = str(get_value(row_dict, ['last_updated', 'date', 'updated_at'], ''))
            
            # Check if SKU exists
            item = db.query(models.InventoryItem).filter(models.InventoryItem.sku == sku).first()
            if item:
                item.name = name
                item.quantity = qty
                item.reorder_level = reorder
                item.supplier_id = sup_id
                item.sales_last_7_days = sales
                item.complaints = comp
                item.last_updated = updated
            else:
                item = models.InventoryItem(
                    sku=sku,
                    name=name,
                    quantity=qty,
                    reorder_level=reorder,
                    supplier_id=sup_id,
                    sales_last_7_days=sales,
                    complaints=comp,
                    last_updated=updated
                )
                db.add(item)
                
        db.commit()
        db.refresh(ingested)
        
        log_event(
            message=f"Ingested CSV: '{file.filename}' ({len(df)} records). Synced directly with SQLite inventory ledger.",
            level="success",
            source="analysis"
        )
        return {"status": "success", "id": ingested.id, "rows": len(df)}
    except Exception as e:
        log_event(f"CSV parsing failure on '{file.filename}': {str(e)}", level="error", source="analysis")
        raise HTTPException(status_code=500, detail=f"CSV parsing failed: {str(e)}")

@router.post("/upload/json")
async def upload_json(payload: dict, db: Session = Depends(get_db)):
    try:
        log_event("Processing manual JSON data ingestion...", level="info", source="analysis")
        ingested = models.IngestedData(
            source_type="json",
            source_name="api_payload",
            raw_content=json.dumps(payload),
            parsed_data=json.dumps(payload)
        )
        db.add(ingested)
        db.commit()
        db.refresh(ingested)
        log_event("JSON data ingestion completed successfully.", level="success", source="analysis")
        return {"status": "success", "id": ingested.id}
    except Exception as e:
        log_event(f"JSON ingestion failed: {str(e)}", level="error", source="analysis")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/analyze/url")
async def analyze_url(req: UrlRequest, db: Session = Depends(get_db)):
    try:
        log_event(f"Initiating URL scraping: '{req.url}'", level="info", source="analysis")
        response = requests.get(req.url, timeout=120)
        soup = BeautifulSoup(response.text, "html.parser")
        
        text_content = soup.get_text(separator=' ', strip=True)
        
        ingested = models.IngestedData(
            source_type="url",
            source_name=req.url,
            raw_content=response.text,
            parsed_data=json.dumps({"text_length": len(text_content), "title": soup.title.string if soup.title else ""})
        )
        db.add(ingested)
        db.commit()
        db.refresh(ingested)
        
        log_event(
            message=f"Ingested URL data: '{req.url}' successfully. Parsing HTML body...",
            level="success",
            source="analysis"
        )
        return {"status": "success", "id": ingested.id, "text_length": len(text_content)}
    except Exception as e:
        log_event(f"URL scraping failed for '{req.url}': {str(e)}", level="error", source="analysis")
        raise HTTPException(status_code=500, detail=f"URL scraping failed: {str(e)}")

@router.post("/live-feed")
async def live_feed(req: LiveFeedRequest, db: Session = Depends(get_db)):
    log_event(f"Live feed event received from source '{req.source}': '{req.content}'", level="warning", source="system")
    ingested = models.IngestedData(
        source_type="live",
        source_name=req.source,
        raw_content=req.content,
        parsed_data=json.dumps({"credibility": req.credibility})
    )
    db.add(ingested)
    
    # Check if this feed represents a warning or alert threat
    content_lower = req.content.lower()
    if any(keyword in content_lower for keyword in ["delay", "strike", "block", "disruption", "risk", "shortage"]):
        # Create a real, live threat Alert in the Alert table!
        alert = models.Alert(
            title=f"Disruption detected via {req.source}",
            message=req.content,
            is_resolved=False
        )
        db.add(alert)
        log_event(f"DYNAMIC THREAT ALERT TRIGGERED: '{alert.title}' created from live feed context.", level="warning", source="system")
        
    db.commit()
    db.refresh(ingested)
    
    log_event("Live feed ingested. Queueing System reasoning chain...", level="success", source="system")
    return {"status": "success", "id": ingested.id}
