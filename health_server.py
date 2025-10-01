from fastapi import FastAPI
import uvicorn
import requests

app = FastAPI()

@app.get("/health")
def health():
    try:
        resp = requests.post(
            "http://localhost:9636",
            json={"jsonrpc": "2.0", "method": "eth_blockNumber", "params": [], "id": 1},
            timeout=3,
        )
        if resp.status_code == 200:
            block_number = resp.json().get("result", "0x0")
            return {"status": "ok", "latestBlock": int(block_number, 16)}
        else:
            return {"status": "error", "detail": "RPC unhealthy"}
    except Exception as e:
        return {"status": "error", "detail": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
