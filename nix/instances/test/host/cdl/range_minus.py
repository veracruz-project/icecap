def ranges_minus(whole, no):
    FRESH = 1
    EXHAUSTED = 2
    OPEN = 3
    CLOSED = 4

    no = iter(no)

    state = FRESH

    for start, end in whole:
        if state == EXHAUSTED:
            yield start, end
        elif state == FRESH:
            try:
                n_start, n_end = next(no)
            except StopIteration:
                yield start, end
                state = EXHAUSTED
        elif state == OPEN:


        if n_end is None:
            break
        if n_end < w_end:
            if w_start < n_end:
                w_start = n_end
            break
        while True:
            try:
                n_start, n_end = next(no)
            except StopIteration:
                yield w_start, w_end
                yield from whole
                return
            if n_end <= w_start:
                continue
            if w_end <= n_start:
                yield w_start, w_end
                continue
            if w_start < n_start:
                yield w_start, n_start
                w_start = n_end

            if n_start <= w_start:

            if w_start <= n_end:


        if no is None:
            yield w_start, w_end
            continue
        while True:
            try:
                n_start, n_end = next(no)
            except StopIteration:
                yield w_start, w_end
                break
            if n_start < w_end:
                yield w_start, n_end
