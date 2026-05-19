from datetime import datetime

class NoiseFilter:
    def __init__(self):
        self.seen_claims = set()

    def filter_data(self, data_stream: list) -> list:
        """
        Filters out duplicates, stale data, and low-quality content.
        Data format: {"id": "...", "content": "...", "timestamp": datetime}
        """
        clean_data = []
        now = datetime.utcnow()

        for item in data_stream:
            # 1. Duplicate filtering
            content_hash = hash(item.get("content", "").lower().strip())
            if content_hash in self.seen_claims:
                continue
                
            # 2. Stale data filtering (older than 7 days)
            item_time = item.get("timestamp")
            if item_time and (now - item_time).days > 7:
                continue
                
            # 3. Low-quality filtering (too short)
            if len(item.get("content", "")) < 10:
                continue

            self.seen_claims.add(content_hash)
            clean_data.append(item)

        return clean_data
