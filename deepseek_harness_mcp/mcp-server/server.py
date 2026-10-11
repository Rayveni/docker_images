# server.py
from fastmcp import FastMCP

# stateless_http УБРАН из конструктора
mcp = FastMCP(name="CalculatorServer")

@mcp.tool
def add(a: float, b: float) -> float:
    """Складывает два числа."""
    return a + b

if __name__ == "__main__":
    # stateless_http передается в run()
    mcp.run(
        transport="streamable-http",
        host="0.0.0.0",
        port=8000,
        stateless_http=True,
    )