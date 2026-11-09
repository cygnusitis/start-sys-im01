# START-SYS Admin Dashboard

Local, database-connected admin dashboard for the START-DOST Membership Record Management System
(Flask + PyMySQL backend, plain HTML/CSS/JS frontend, MariaDB database `startsys`).

## Requirements
- Python 3.10 or newer
- MariaDB 10.4+ running locally with the `startsys` database already loaded (tables, 45 `vw_*` views, 7 stored procedures, 3 triggers, and the data)
- A MariaDB user with SELECT, INSERT, UPDATE, DELETE and EXECUTE on `startsys`

## Project structure
```
startsys-dashboard/
├── app.py               Flask backend and JSON API (the only code that touches MariaDB)
├── requirements.txt     Flask, PyMySQL, python-dotenv
├── .env.example         Database settings template (copy to .env)
├── templates/index.html Single page shell with sidebar navigation
└── static/
    ├── css/style.css    START-SYS styling (yellow #ffdd00, off-white #fafafa, blue #0099ff)
    ├── js/app.js        Pages, tables, forms, charts
    └── img/start-sys-wordmark.png
```

## Install (first time only)
Windows (PowerShell):
```
cd startsys-dashboard
py -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```
macOS / Linux:
```
cd startsys-dashboard
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```
Edit `.env` with your MariaDB host, port, user, password and database name. The file stays on the server; the browser never sees it.

## Start
```
python app.py
```
Open http://127.0.0.1:5000 (change `PORT` in `.env` if 5000 is taken). The header pill shows "Connected: startsys" when the database is reachable.

## Stop
Press `Ctrl + C` in the terminal running the app. To start again later, activate the virtual environment and run `python app.py`.

## Loading the database
The app expects the `startsys` database to exist already. To load it on a new computer, restore a SQL dump made on the machine that has the data:
```
mysqldump -u root -p --routines --triggers startsys > startsys.sql     (on the source machine)
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS startsys CHARACTER SET utf8mb4"
mysql -u root -p startsys < startsys.sql                                (on the demo machine)
```

## How the interface uses the database
- Analytics and the dashboard charts read the existing `vw_*` views (`SELECT * FROM vw_...`). Nothing is recomputed in Python.
- Dashboard cards separate unique members (`members`) from membership assignments (`membership_record`); the status cards show record counts with unique-member counts underneath.
- Members and Membership Records use parameterized SQL. Form fields are built from `information_schema`, so auto-increment and generated columns are never written.
- Deleting a member who still has membership records is blocked by the foreign key and the app shows why. Nothing cascades.
- Inserting, deleting, or changing the status of a membership record fires the existing triggers; results appear under Audit Logs. The `Changed_By` value is whichever MariaDB user the app connects as.
- The Database page lists stored procedures found in `information_schema` and runs them with a confirmation prompt.

## Troubleshooting
- "Database offline" or "Cannot reach the database": MariaDB is not running, or `.env` is wrong.
- Empty Analytics tab: views named `vw_*` were not found in the configured database.
