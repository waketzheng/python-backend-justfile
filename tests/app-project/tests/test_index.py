from __future__ import annotations

from typing import TYPE_CHECKING

import pytest

if TYPE_CHECKING:
    from asynctor.testing import AsyncClient


@pytest.mark.anyio
async def test_index(client: AsyncClient) -> None:
    r = await client.get("/")
    assert r.text == "Hello World"
