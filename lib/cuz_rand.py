import random
import string


def random_split(data: str, times: int = 20) -> list[str]:
    """split string randomly"""
    if len(data) < times:
        raise ValueError(
            "Error occurred when trying to randomly split a string, found length too short"
        )
    if times == len(data):
        return list(data)
    result: list[str] = []
    should: int = len(data) // times
    leftover: int = 0
    index: list[int] = []
    for _ in range(times - 1):
        index.append(random.randint(1, should) + random.randint(1, leftover))
        leftover += should - index[-1]
    index.append(leftover)
    prev: int = 0
    for ind in index:
        result.append(data[prev:ind])
        prev = ind
    return result


def random_text(
    max: int,
    min: int = 1,
    charset: str = string.digits + string.punctuation,
) -> str:
    """return random text"""
    return "".join(random.choice(charset) for _ in range(min, max))
