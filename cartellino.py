from datetime import datetime, timedelta
from typing import Optional


def turn_end_time(
    start_time_str: str,
    work_time_str: str,
    lunch_time_str: str,
    leisure_time_str: Optional[str] = None,
) -> str:
    """
    Calculates when a work turn finishes based on start time, work time, and lunch time.

    Args:
        start_time_str: The start time of the work shift in 'HH:MM' format.
        work_time_str: The total duration of work in 'HH:MM' format.
        lunch_time_str: The duration of the lunch break in 'HH:MM' format.
        leisure_time_str: The duration of leisure time in 'HH:MM' format. It's optional.

    Returns:
        The calculated finish time of the work shift in 'HH:MM' format.
    """
    time_format = "%H:%M"

    # Convert string inputs to datetime and timedelta objects
    try:
        start_time = datetime.strptime(start_time_str, time_format)
        work_duration_parts = [int(part) for part in work_time_str.split(":")]
        work_duration = timedelta(
            hours=work_duration_parts[0],
            minutes=work_duration_parts[1],
        )
        lunch_duration_parts = [int(part) for part in lunch_time_str.split(":")]
        lunch_duration = timedelta(
            hours=lunch_duration_parts[0],
            minutes=lunch_duration_parts[1],
        )
        leisure_duration = timedelta()
        if leisure_time_str:
            leisure_duration_parts = [int(part) for part in leisure_time_str.split(":")]
            leisure_duration = timedelta(
                hours=leisure_duration_parts[0],
                minutes=leisure_duration_parts[1],
            )
    except ValueError:
        return "Invalid time format. Please use 'HH:MM'."

    # Calculate the finish time by adding the work and lunch durations to the start time
    finish_time = start_time + work_duration + lunch_duration - leisure_duration

    return finish_time.strftime(time_format)


def time_to_turn_end(
    start_time_str: str,
    work_time_str: str,
    lunch_time_str: str,
    leisure_time_str: Optional[str] = None,
) -> str:
    """
    Calculates the remaining time until the work turn finishes.

    Args:
        start_time_str: The start time of the work shift in 'HH:MM' format.
        work_time_str: The total duration of work in 'HH:MM' format.
        lunch_time_str: The duration of the lunch break in 'HH:MM' format.
        leisure_time_str: The duration of leisure time in 'HH:MM' format. It's optional.

    Returns:
        The remaining time until the work shift finishes in 'HH:MM' format.
    """
    finish_time_str = turn_end_time(
        start_time_str, work_time_str, lunch_time_str, leisure_time_str
    )
    time_format = "%H:%M"

    try:
        finish_time = datetime.strptime(finish_time_str, time_format)
        current_time = datetime.now().replace(second=0, microsecond=0)
        finish_time = finish_time.replace(
            year=current_time.year, month=current_time.month, day=current_time.day
        )
    except ValueError:
        return "Invalid time format. Please use 'HH:MM'."

    if finish_time < current_time:
        return "00:00"

    remaining_duration = finish_time - current_time
    total_minutes = int(remaining_duration.total_seconds() // 60)
    hours, minutes = divmod(total_minutes, 60)

    return f"{hours:02}h:{minutes:02}m"
