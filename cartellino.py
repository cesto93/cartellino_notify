from datetime import datetime, timedelta


def calculate_work_turn_finish(
    start_time_str: str, work_time_str: str, lunch_time_str: str
) -> str:
    """
    Calculates when a work turn finishes based on start time, work time, and lunch time.

    Args:
        start_time_str: The start time of the work shift in 'HH:MM:SS' format.
        work_time_str: The total duration of work in 'HH:MM:SS' format.
        lunch_time_str: The duration of the lunch break in 'HH:MM:SS' format.

    Returns:
        The calculated finish time of the work shift in 'HH:MM:SS' format.
    """
    time_format = "%H:%M:%S"

    # Convert string inputs to datetime and timedelta objects
    try:
        start_time = datetime.strptime(start_time_str, time_format)
        work_duration_parts = [int(part) for part in work_time_str.split(":")]
        work_duration = timedelta(
            hours=work_duration_parts[0],
            minutes=work_duration_parts[1],
            seconds=work_duration_parts[2],
        )
        lunch_duration_parts = [int(part) for part in lunch_time_str.split(":")]
        lunch_duration = timedelta(
            hours=lunch_duration_parts[0],
            minutes=lunch_duration_parts[1],
            seconds=lunch_duration_parts[2],
        )
    except ValueError:
        return "Invalid time format. Please use 'HH:MM:SS'."

    # Calculate the finish time by adding the work and lunch durations to the start time
    finish_time = start_time + work_duration + lunch_duration

    return finish_time.strftime(time_format)


# Example usage:
start = "08:00:00"
work = "08:00:00"
lunch = "0:30:00"

finish_time = calculate_work_turn_finish(start, work, lunch)
print(f"The work turn finishes at: {finish_time}")
