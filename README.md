# NGI Invoicing Template

Automates invoice generation from Notion timesheet entries.

## Prerequisites

- [Nix](https://nix.dev/install-nix)
- Notion access
  - Properly logging hours into time sheets table in notion.

## Setup

1. Clone this repository.
2. Edit `invoice.typ` with your details. Payment details, address etc. adjust the fields accordingly.

   eg.
   ```typst
   [*Account No.*], [*123456789*],
   [*SWIFT*], [*ABCDUS33*],
   ```
3. Run `direnv allow` or `nix develop` to load the environment.

## Usage

1. Export your time sheets table from Notion (downloads a ZIP file).
2. Extract the `.csv` file into the `data/` directory.
> [!IMPORTANT]
> Do **not** use the file ending with `_all.csv` from the Notion export. The `_all.csv` file exports raw database entries in some random order which will cause your invoice entries to become out of order.
> Always use the regular `.csv` export which preserves the order.
3. Run the command to create the invoice pdf:
  ```bash
  create-invoice "data/path/to/Your_Notion_Export.csv"
  ```
  For **Summer of Nix** participants, please specify a custom invoice title containing your username (e.g., for 2026):
  ```bash
  create-invoice "data/path/to/Your_Notion_Export.csv" --title "<username>-son-2026-invoice"
  ```
  The PDF invoice will be generated in `invoices/`.

### CLI Options

- `--title`: Custom invoice filename (e.g., `--title "my-custom-invoice"`).
- `--rate`: Hourly rate in Euros. Overrides interactive prompt and saves to `config.json`.
- `--project`: Project name (e.g., `--project "Summer of Nix"`). Overrides interactive prompt and saves to `config.json`.

### How it Works

- On the first run, prompts for your hourly rate and project name and saves these to a local `config.json` which is gitignored.
- Reads your timesheet, filters out rows with 0 or empty hours, and computes the costs and outputs the data to `build/invoice_data.csv`.
- Invoice date is set as the current date, due date 30 days after the invoice date, and invoice period is derived from the earliest work date found in the CSV (e.g., `2026-06 june`).
- Saves dates, period, and title to `build/invoice_meta.json`.
- Run `typst compile`. The template formats the currencies and generates the PDF in `invoices`.

## Optional workflow Recommendations

- You have two ways of keeping track of time sheet entries.
  - The first is to build a daily habit of entering your hours into Notion at the end of the day.
  - Use a personal time tracking software which allows exporting to csv. You can use these csv exports to import them into Notion which can append them into your time sheets table. eg. [timetagger](https://github.com/almarklein/timetagger) is one such recommendation, which is used by one of our team members.
- [direnv](https://github.com/direnv/direnv/wiki/Nix#setting-up-a-project-to-use-nix) + [nix-direnv](https://github.com/nix-community/nix-direnv) setup heavily recommended.
- You can optionally push this repo after cloning it, to a private repository and remove `data, build, invoices, config.json` from .gitignore to keep track of everything.
