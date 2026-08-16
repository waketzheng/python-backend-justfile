from __future__ import annotations

from contextlib import suppress
from typing import TYPE_CHECKING

import pytest

with suppress(ImportError):
    from asynctor.testing import anyio_backend_fixture, async_client_fixture
    from asynctor.utils import ExtendSyspath

with ExtendSyspath(__file__):
    from main import app

if TYPE_CHECKING:
    from asynctor.testing import AsyncClient

anyio_backend = anyio_backend_fixture()
client = async_client_fixture(app)


@pytest.mark.anyio
async def test_index(client: AsyncClient) -> None:
    r = await client.get("/")
    assert r.text == "Hello World"
