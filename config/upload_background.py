from pathlib import Path
from kurra.db import upload
from httpx import Client

c = Client(auth=('admin', 'admin'))
for f in Path(Path(__file__).parent.parent / "resources/background").rglob('*.ttl'):
    upload("http://localhost:3030/fuseki-ogc/", f, "http://background", append=True, http_client=c)
    print(f"uploaded {f}")
