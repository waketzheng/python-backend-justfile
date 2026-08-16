import pytest


@pytest.mark.anyio
async def test_index(client):
    r = await client.get("/")
    assert r.text == "Hello World"
