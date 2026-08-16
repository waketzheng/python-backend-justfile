import pytest
from asynctor.testing import AsyncClient


@pytest.mark.anyio
async def test_index(client: AsyncClient) -> None:
    r = await client.get("/")
    assert r.text == "Hello World"
