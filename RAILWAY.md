# Deploy on Railway

The repo includes a `Dockerfile` and `railway.json`. Railway builds the image, terminates HTTPS, and routes traffic to the app over HTTP on `$PORT`. One MySQL service can be shared by irvis, scvis, and eevis; each app creates its own database on first start.

1. In the Railway project, use the shared **MySQL** database service (add one if the project has none).
2. Add a service from this GitHub repo (`vaccs/eevis-go`), using the `railway` branch until it is merged.
3. In the service's **Variables**, set:

```text
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_USER=${{MySQL.MYSQLUSER}}
DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
DB_NAME=eevis
DB_CREATE_DATABASE=true
SESSION_SECRET=<long random string, e.g. output of: openssl rand -base64 32>
ADMIN_EMAIL=<your email>
ADMIN_PASSWORD=<initial admin password>
GITHUB_TOKEN=<token, if the issue feature is used>
```

4. Under **Settings → Networking**, click **Generate Domain**. The app is at `https://<domain>/eevis`.

On startup the app creates the `users` table if missing, and creates the admin user from `ADMIN_*` only when the table is empty. After the first login you can remove `ADMIN_PASSWORD`.

The image sets `APP_HOST=0.0.0.0` and `USE_TLS=false`; the app listens on Railway's `PORT` when `APP_PORT` is not set.
