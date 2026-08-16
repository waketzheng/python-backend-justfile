import pytest
from asynctor.testing import AsyncClient, anyio_backend_fixture, async_client_fixture
from main import app

anyio_backend = anyio_backend_fixture()
client = async_client_fixture(app)


@pytest.mark.anyio
async def test_index(client: AsyncClient) -> None:
    r = await client.get("/")
    assert r.text == "Hello World"
