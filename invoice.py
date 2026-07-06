import csv
import argparse
import datetime
import json
import subprocess
import os


def get_config(cli_rate=None, cli_project=None):
    config_file = "config.json"

    rate = None
    project = None

    if os.path.exists(config_file):
        try:
            with open(config_file, "r", encoding="utf-8") as f:
                config = json.load(f)
                if "hourly_rate" in config:
                    rate = float(config["hourly_rate"])
                if "project_name" in config:
                    project = config["project_name"]
        except (json.JSONDecodeError, ValueError):
            pass

    if cli_rate is not None:
        rate = float(cli_rate)

    if cli_project is not None:
        project = cli_project

    if rate is None:
        while True:
            try:
                rate_input = input("Please enter your hourly rate in Euros: ")
                rate = float(rate_input.replace(",", "."))
                break
            except ValueError:
                print("Invalid input. Please enter a valid number.")

    if project is None:
        project_input = input(
            "Please enter your project name (e.g., 'Summer of Nix' or 'NGI Nix contract'): "
        ).strip()
        project = project_input if project_input else "NGI Nix contract"

    # Save to config.json
    with open(config_file, "w", encoding="utf-8") as f:
        json.dump({"hourly_rate": rate, "project_name": project}, f, indent=4)

    return rate, project


def create_invoice(input_file, cli_rate=None, cli_title=None, cli_project=None):
    os.makedirs("build", exist_ok=True)
    os.makedirs("data", exist_ok=True)
    os.makedirs("invoices", exist_ok=True)

    rate, project = get_config(cli_rate, cli_project)

    with open(input_file, "r", newline="", encoding="utf-8-sig") as f_in:
        reader = csv.DictReader(f_in)
        rows = list(reader)

    invoice_records = []
    work_dates = []

    for row in rows:
        notes = row.get("Notes", "Unknown Task")

        if "Hours" not in row or not str(row["Hours"]).strip():
            print(f"Warning: Skipping row with empty hours (Notes: '{notes}')")
            continue

        hours_str = str(row["Hours"]).replace(",", ".")
        try:
            hours_float = float(hours_str)
        except ValueError:
            hours_float = 0.0

        if hours_float == 0.0:
            print(f"Warning: Skipping row with 0 hours (Notes: '{notes}')")
            continue

        cost_float = hours_float * rate

        date_val = row.get("Date")
        if not date_val:
            date_val = row.get("_Manual date", "")

        if date_val:
            try:
                d_str = date_val[:10]
                d = datetime.datetime.strptime(d_str, "%Y-%m-%d").date()
                work_dates.append(d)
            except ValueError:
                pass

        invoice_records.append(
            {
                "Notes": notes,
                "Hours": hours_float,
                "Date": date_val,
                "Rate": rate,
                "Cost": cost_float,
            }
        )

    def parse_date_for_sort(d_str):
        if not d_str:
            return datetime.date.max
        try:
            return datetime.datetime.strptime(d_str[:10], "%Y-%m-%d").date()
        except ValueError:
            return datetime.date.max

    # Use stable sorting by Date only. This preserves the original row order
    # (i.e., the order you manually arranged them in Notion) for entries on the same day.
    invoice_records.sort(key=lambda r: parse_date_for_sort(r["Date"]))

    invoice_filename = "build/invoice_data.csv"
    invoice_fieldnames = ["Notes", "Hours", "Date", "Rate", "Cost"]
    with open(invoice_filename, "w", newline="", encoding="utf-8") as f_inv:
        writer = csv.DictWriter(f_inv, fieldnames=invoice_fieldnames)
        writer.writeheader()
        writer.writerows(invoice_records)

    today = datetime.date.today()
    due = today + datetime.timedelta(days=30)

    if work_dates:
        target_date = min(work_dates)
    else:
        target_date = today.replace(day=1) - datetime.timedelta(days=1)

    prev_month_name = target_date.strftime("%B").lower()
    prev_month_year = target_date.strftime("%Y")
    prev_month_num = target_date.strftime("%m")

    if cli_title:
        invoice_title = cli_title
    else:
        invoice_title = (
            f"contract-invoice-{prev_month_year}-{prev_month_num}-{prev_month_name}"
        )

    with open("build/invoice_meta.json", "w", encoding="utf-8") as f_meta:
        json.dump(
            {
                "invoice_date": today.strftime("%Y-%m-%d"),
                "due_date": due.strftime("%Y-%m-%d"),
                "invoice_title": invoice_title,
                "period": f"{prev_month_year}-{prev_month_num} {prev_month_name}",
                "project_name": project,
            },
            f_meta,
            ensure_ascii=False,
            indent=4,
        )

    print(f"Successfully processed {input_file} into {invoice_filename}")
    print("Created build/invoice_meta.json")

    pdf_out = f"invoices/{invoice_title}.pdf"
    print(f"Compiling PDF invoice to {pdf_out} ...")
    subprocess.run(["typst", "compile", "invoice.typ", pdf_out])
    print("Done!")


def main():
    parser = argparse.ArgumentParser(
        prog="create-invoice", description="Clean up Notion CSV and prepare PDF data"
    )
    parser.add_argument(
        "file",
        help='Notion CSV file to clean up (e.g., "data/Time sheets ....csv")',
    )
    parser.add_argument(
        "--rate",
        type=float,
        help="Hourly rate in Euros (overrides interactive prompt and saves to config.json)",
    )
    parser.add_argument(
        "--title",
        help="Custom invoice title (e.g., 'my-custom-invoice')",
    )
    parser.add_argument(
        "--project",
        help="Custom project name (e.g., 'Summer of Nix')",
    )

    args = parser.parse_args()
    create_invoice(args.file, args.rate, args.title, args.project)


if __name__ == "__main__":
    main()
