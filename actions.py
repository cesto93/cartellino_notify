from database import get_setting, get_start_time, get_daily_setting
from cartellino import turn_end_time, time_to_turn_end


def work_end(chat_id: int) -> str:
    """
    Calculates and displays the remaining time until the end of the work turn.
    """
    st = get_start_time(chat_id)
    if not st:
        print(
            "Error: Start time not provided and no start time stored for today.\n"
            "Use 'start' command to store it or provide it as an argument."
        )
        raise Exception("Start time not available")

    wt = get_setting("work_time") or "07:12"
    lt = get_setting("lunch_time") or "00:30"
    lrt = get_daily_setting(chat_id, "leisure_time")

    finish_time = turn_end_time(st, wt, lt, lrt)
    remaining_time = time_to_turn_end(st, wt, lt, lrt)
    return f"Time remaining until work turn finishes at {finish_time}.\nRemaining time: {remaining_time}"
