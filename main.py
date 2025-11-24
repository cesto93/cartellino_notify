import argparse

from cartellino import calculate_work_turn_finish


def main():
    """
    Main function to parse arguments and calculate work finish time.
    """
    parser = argparse.ArgumentParser(
        description="A simple tool to calculate work turn finish time."
    )
    parser.add_argument("start_time", help="Start time in 'HH:MM:SS' format")
    parser.add_argument(
        "--work-time",
        dest="work_time",
        required=False,
        default="07:12:00",
        metavar="HH:MM:SS",
        help="Work duration in 'HH:MM:SS' format. Defaults to 07:12:00",
    )
    parser.add_argument(
        "--lunch_time",
        required=False,
        help="Lunch duration in 'HH:MM:SS' format. Defaults to 0:30:00",
        default="0:30:00",
    )

    args = parser.parse_args()

    finish_time = calculate_work_turn_finish(
        args.start_time, args.work_time, args.lunch_time
    )
    print(f"The work turn finishes at: {finish_time}")


if __name__ == "__main__":
    main()
