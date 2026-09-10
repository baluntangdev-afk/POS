# -*- coding: utf-8 -*-
"""User-manual content for POS Mobile. Plain-language, step-by-step."""

from manual_helpers import p, lead, h3, h4, ul, ol, steps, note, table, pre

SECTIONS = []


def add(title, body):
    SECTIONS.append((title, body))


# ---------------------------------------------------------------------------
add("About POS Mobile", "".join([
    lead("POS Mobile (shown in the app as <b>Cartivo</b>) is a point-of-sale "
         "app that runs on an Android phone or tablet. It rings up sales, prints "
         "receipts to a Bluetooth or built-in thermal printer, tracks your "
         "cashiers' totals, and can receive online orders from your storefront."),
    h3("What makes it different"),
    ul([
        "<b>Works offline.</b> Every sale, product, user and report is stored on "
        "the device itself. You can take orders and print receipts with no "
        "internet connection at all.",
        "<b>Internet is only needed for online orders.</b> The live <i>Orders</i> "
        "feed (orders placed through your website / kiosk) and one-time device "
        "registration need a connection. Nothing else does.",
        "<b>Backups happen automatically.</b> The app saves a full backup of its "
        "data to the phone's Downloads folder every few hours.",
    ]),
    h3("Who does what — the three roles"),
    table(["Role", "Can do"], [
        ["<b>Cashier</b>",
         "Take orders, take payment, print &amp; void receipts (void needs a "
         "supervisor PIN), view transactions, run their own X-Reading and Daily "
         "Report, view online Orders, connect a printer."],
        ["<b>Supervisor</b>",
         "Everything a cashier can do, <i>plus</i> Inventory, Users, Store "
         "Information, CSV import, Backup &amp; Restore, and authorizing a "
         "Z-Reading."],
        ["<b>Admin</b>",
         "Everything. The first account on a new device is an Admin."],
    ]),
    note("Throughout this manual, steps marked <span class='role'>Admin</span> "
         "or <span class='role'>Supervisor</span> are hidden from cashiers."),
]))

# ---------------------------------------------------------------------------
add("Before you start", "".join([
    h3("What you need"),
    ul([
        "An <b>Android phone or tablet</b> (Android 5.0 / API 21 or newer). A "
        "tablet gives a nicer two-column ordering screen but a phone works "
        "fully.",
        "The <b>POS Mobile app</b> installed. Your IT person builds and installs "
        "it — see the Technical Manual.",
        "A <b>thermal receipt printer</b> — either a Bluetooth printer, or a "
        "device with a built-in printer (some rugged Android POS terminals have "
        "one). Optional, but you can't print receipts without one.",
        "For online orders only: a <b>Wi-Fi or mobile data</b> connection and "
        "the store's registration details from your provider.",
    ]),
    h3("First launch"),
    p("The very first time the app opens on a brand-new device it creates a "
      "single <b>Admin</b> account for you:"),
    table(["Field", "Value"], [
        ["Name", "Admin"],
        ["Role", "Admin"],
        ["PIN", "<code>000000</code> (six zeros)"],
    ]),
    note("You will be forced to change this PIN the first time you sign in. "
         "You cannot reach the app with the default PIN still active.", "warn"),
]))

# ---------------------------------------------------------------------------
add("First-time setup (Admin)", "".join([
    lead("Do these once, in order, on a new device. The app will actually "
         "prompt you for the first few automatically the first time an Admin "
         "reaches the dashboard."),
    steps([
        "<b>Sign in and set your PIN.</b> On the account screen tap <b>Admin</b>, "
        "type <code>000000</code>, then choose a new 6-digit PIN and confirm it. "
        "(It can't be <code>000000</code>.)",
        "<b>Set the Store ID.</b> A pop-up asks for a unique Store ID and "
        "suggests one — accept it or type your own, then tap <b>Confirm</b>. "
        "This ID identifies your store to the online-orders service.",
        "<b>Fill in Store Information.</b> The Store Information form opens: "
        "enter Store Name (required), Address, TIN, and a Terminal Name (e.g. "
        "“Front Counter”). Tap <b>Save</b>.",
        "<b>Add payment methods.</b> On the same screen, in the Payment Methods "
        "card, add each method you accept (Cash, GCash, card, etc.). You need at "
        "least one before you can take payment.",
        "<b>Add your employees.</b> When prompted “No Employees Added” "
        "tap <b>Add Employee</b> (or open <b>Users</b> later). Create a card for "
        "each cashier and supervisor.",
        "<b>Import your products.</b> When prompted “No Products Found” "
        "tap <b>Import Products</b> and load a products CSV file (format below). "
        "You can also add products by hand in Inventory.",
        "<b>Connect a printer.</b> Go to <b>Settings → Printer Setup</b> and "
        "pair your Bluetooth receipt printer.",
        "<b>Register for online orders (optional).</b> Saving Store Information "
        "automatically registers this device with the online-orders service. "
        "It usually starts as “pending approval” until your provider "
        "approves it — see the <i>Orders</i> section.",
    ]),
    note("You can skip the Employees and Products prompts and come back to them "
         "later — only the Store ID and Store Name are mandatory."),
]))

# ---------------------------------------------------------------------------
add("Signing in and PINs", "".join([
    h3("Signing in"),
    steps([
        "Open the app. You see a grid of account cards, one per active user.",
        "Tap your card.",
        "Type your <b>6-digit PIN</b> on the keypad. Sign-in happens "
        "automatically once the sixth digit is entered — there is no "
        "“enter” button.",
        "A wrong PIN clears the field and shows an error; try again. Tap the "
        "back arrow to pick a different account.",
    ]),
    note("There is no “remember me”. Every time the app is fully "
         "closed and reopened, everyone signs in again. Closing the app is the "
         "safest way to lock the till when you step away."),
    h3("First-login PIN change"),
    p("Any new account (and any account whose PIN an admin has reset) starts on "
      "the shared default PIN. On first sign-in the app makes that user choose a "
      "personal 6-digit PIN and confirm it before anything else."),
    h3("Forgotten PIN"),
    p("PINs can't be recovered, only reset. An Admin or Supervisor opens "
      "<b>Users</b>, taps the &#8942; menu on that person's card, chooses "
      "<b>Reset PIN</b>, and confirms. The user then signs in with the default "
      "PIN and sets a new one."),
]))

# ---------------------------------------------------------------------------
add("The Dashboard", "".join([
    lead("The home screen after sign-in. It shows a greeting, the time, your "
         "name and role, a <b>Sign Out</b> button, a live-orders status pill, "
         "and a grid of tiles."),
    table(["Tile", "Opens", "Who sees it"], [
        ["New Order", "The ordering screen — take a sale", "Everyone"],
        ["Transactions", "History of completed sales", "Everyone"],
        ["Inventory", "Products, categories, modifiers",
         "<span class='role'>Admin / Supervisor</span>"],
        ["Cashier Accounting", "X-Reading, Daily Report, Z-Reading", "Everyone"],
        ["Orders", "Live online orders from your storefront "
         "(shows a red count badge when orders are waiting)", "Everyone"],
        ["Settings", "Printer, store info, backups, CSV, export password",
         "Everyone (some items Admin-only inside)"],
        ["Users", "Staff accounts",
         "<span class='role'>Admin / Supervisor</span>"],
    ]),
    h3("The live-orders status pill"),
    p("Under the “Cartivo” logo a small pill shows the online-orders "
      "connection:"),
    ul([
        "<b>Live orders connected</b> — receiving online orders in real time.",
        "<b>Connecting… / Reconnecting…</b> — working on it.",
        "<b>Live orders off</b> — not connected (no internet, device not yet "
        "approved, or the feature isn't set up). Walk-in sales are unaffected.",
    ]),
]))

# ---------------------------------------------------------------------------
add("New Order — taking a sale", "".join([
    lead("Dashboard → <b>New Order</b>. On a tablet the product grid and the "
         "cart sit side by side; on a phone the cart is a bar at the bottom that "
         "opens as a sheet."),
    steps([
        "<b>Pick a category</b> from the chip row (or <b>All</b>), then "
        "<b>tap a product</b>.",
        "In the product sheet, choose a <b>Variant</b> if the product has them "
        "(e.g. Small / Large — one is required), tick any <b>modifiers</b> "
        "(required groups are marked; optional groups show a max count), type "
        "<b>Notes</b> if needed (“no onions”), set the <b>quantity</b>, "
        "then tap <b>Add to Cart</b>.",
        "Repeat for every item. The cart shows a running total.",
        "Set the <b>order type</b> at the top of the cart: <b>Dine In</b> or "
        "<b>Take Out</b>.",
        "Tap a cart line to expand it — change quantity, edit notes, or "
        "remove it. <b>Clear</b> empties the whole cart.",
        "Apply discounts if needed (next section).",
        "Tap <b>Proceed to Payment</b>.",
    ]),
    note("A line item that has a discount on it is locked — its quantity "
         "can't be changed. Remove the discount (or the line) to edit it."),
]))

# ---------------------------------------------------------------------------
add("Discounts", "".join([
    p("There are two ways to discount, both reached from the cart:"),
    table(["Where", "How"], [
        ["<b>Per item</b>",
         "Expand a cart line — discounts are applied through the "
         "<b>Apply Order Discount</b> screen by selecting which items (and how "
         "many of each) the discount covers."],
        ["<b>Whole order</b>",
         "Tap <b>Apply Order Discount</b> in the cart footer."],
    ]),
    h3("Discount types"),
    ul([
        "<b>Senior / PWD</b> — the statutory discount. Requires the "
        "cardholder's <b>ID number</b> and <b>name</b>. The covered items become "
        "VAT-exempt and the discount is calculated for you. Both fields are "
        "printed on the receipt as a <code>LESS:</code> line.",
        "<b>Promo</b> — requires a <b>promo code</b>.",
    ]),
    steps([
        "On the <b>Apply Discount</b> screen, tick the items to discount. If an "
        "item has quantity &gt; 1 you can choose how many units are covered.",
        "Pick <b>Senior/PWD</b> or <b>Promo</b>.",
        "Fill in the ID + name (Senior/PWD) or the code (Promo).",
        "Check the summary (selected total, VAT exempt, discount amount).",
        "Tap <b>Apply Discount</b>.",
    ]),
    note("Items that are already discounted show a lock icon and can't be "
         "selected again."),
]))

# ---------------------------------------------------------------------------
add("Payment", "".join([
    lead("The payment screen shows the order summary with a full VAT breakdown "
         "(VATable sales, VAT-exempt sales, VAT, discount) and the total due."),
    steps([
        "Tap a <b>payment method</b>. The methods shown are the ones set up in "
        "Store Information.",
        "For <b>Cash</b>: enter the amount the customer handed over. The sheet "
        "shows the <b>change</b> due. Confirm.",
        "For <b>GCash / card / any other method</b>: enter a <b>reference "
        "number</b> and confirm.",
        "The selected method shows a tick and a caption (cash tendered + change, "
        "or the reference).",
        "Tap <b>Confirm Payment · PHP&nbsp;…</b> at the bottom.",
        "The receipt screen opens. The sale is now recorded.",
    ]),
    note("Only one payment method per sale. To change it, tap the method again "
         "before confirming.", "note"),
    note("“No payment methods configured” means an Admin still needs to "
         "add one in <b>Settings → Store Information → Payment "
         "Methods</b>.", "warn"),
]))

# ---------------------------------------------------------------------------
add("Receipts", "".join([
    h3("Reading the receipt"),
    p("The on-screen receipt mirrors what prints: store name / address / TIN, "
      "“Sales Invoice”, date and <b>SI#</b> (invoice number), cashier, "
      "the item lines, the VAT summary, payment details, and “Thank "
      "You!”. A green banner confirms <b>Payment Successful</b>; a voided "
      "sale shows a red <b>VOIDED</b> stamp."),
    h3("Printing"),
    ul([
        "<b>Print (Built-in)</b> — appears if the device has an internal "
        "printer.",
        "<b>Print (Bluetooth)</b> — appears if a Bluetooth printer is "
        "saved.",
        "If neither is set up, a note points you to <b>Settings → Printer "
        "Setup</b>.",
    ]),
    h3("After a sale"),
    ul([
        "<b>New Order</b> (top right) — start the next sale.",
        "Back arrow — returns to the dashboard.",
    ]),
    h3("Void Transaction"),
    p("Voids a completed sale (there is no partial refund in this app — a "
      "void cancels the whole transaction)."),
    steps([
        "On the receipt tap <b>Void Transaction</b>.",
        "Type a <b>reason</b> (required).",
        "Pick a <b>supervisor or admin</b> as the authorizer and have them enter "
        "their <b>PIN</b>.",
        "Tap <b>Void Transaction</b>. The receipt now shows the VOIDED stamp and "
        "the reason.",
    ]),
    note("A sale can no longer be voided once it has been included in a closed "
         "X-Reading, Daily Report, or Z-Reading. The receipt says so and hides "
         "the button.", "warn"),
]))

# ---------------------------------------------------------------------------
add("Transactions", "".join([
    lead("Dashboard → <b>Transactions</b>. Every completed sale, newest "
         "first."),
    ul([
        "<b>Search</b> by invoice number (e.g. <code>#000123</code>).",
        "<b>Filter by date</b> with the calendar icon.",
        "Scroll to load more; pull down to refresh.",
        "Tap a row to open its <b>receipt</b> (where you can reprint or void).",
        "Voided sales are marked and can't be voided again.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Orders — online / storefront orders", "".join([
    lead("Dashboard → <b>Orders</b>. This is a live feed of orders placed "
         "somewhere else — your website, a kiosk, a delivery channel — "
         "and pushed to this device. It is separate from the walk-in sales you "
         "ring up in New Order."),
    h3("Getting notified"),
    ul([
        "When the app is open, a coloured toast appears for every new, updated, "
        "or cancelled order, on whatever screen you're on.",
        "A device notification also fires, so you see new orders even when the "
        "app is in the background.",
        "The Orders tile on the dashboard shows a red count of orders still "
        "needing attention.",
    ]),
    h3("Working an order"),
    steps([
        "Open <b>Orders</b>. Tabs across the top filter by status; each shows a "
        "count.",
        "Tap an order card to see its full detail (customer, items, fulfilment "
        "type — on-site / pickup / delivery).",
        "Move the order along with the status control: <b>Pending → "
        "Preparing → Ready → Fulfilled</b>.",
        "<b>Cancel</b> an order that can't be fulfilled (not available once it's "
        "already fulfilled).",
        "Pull down to refresh the list.",
    ]),
    note("If Orders shows “Can't load orders” with a message about the "
         "store ID or configuration, the device's registration was rejected — "
         "check <b>Settings → Store Information</b> and the registration "
         "status card there.", "warn"),
]))

# ---------------------------------------------------------------------------
add("Cashier Accounting", "".join([
    lead("Dashboard → <b>Cashier Accounting</b>. Three reports, each with a "
         "live view, a <b>Close &amp; Print</b> action, and a <b>History</b> of "
         "past closed copies you can reprint."),
    table(["Report", "Scope", "Closing"], [
        ["<b>X-Reading</b>",
         "A running snapshot of <i>your own</i> sales since your last X-Reading "
         "— payment breakdown, transaction / void / refund counts, "
         "discounts, VAT, cash collected, average / highest / lowest sale.",
         "<b>Close &amp; Print</b> ends the current period and starts a fresh "
         "one. A simple confirm."],
        ["<b>Daily Report</b> (Cashier Report)",
         "<i>Your own</i> VAT and cash summary for the day — gross sales, "
         "VATable / VAT / VAT-exempt, net of tax, sales by product, and a cash "
         "ledger.",
         "<b>Close &amp; Print</b>, simple confirm."],
        ["<b>Z-Reading</b>",
         "The <i>store-wide</i> end-of-day close — all cashiers, beginning "
         "and ending balance, grand totals, sales by cashier, a Z-counter that "
         "increments each close.",
         "<b>Close &amp; Print</b> requires a <b>supervisor / admin PIN</b> to "
         "authorize."],
    ]),
    h3("To close a reading"),
    steps([
        "Open the reading. Review the on-screen figures.",
        "Tap <b>Close &amp; Print …</b> (disabled if there were no "
        "transactions in the period).",
        "Confirm (Z-Reading: also pick an authorizer and enter their PIN).",
        "The reading is saved to History and sent to the printer. If printing "
        "fails you still keep the closed record — reprint it from History.",
    ]),
    note("Closing is permanent and can't be undone. It also “locks” "
         "every transaction in that period against voiding.", "warn"),
    h3("Exporting transactions"),
    p("The <b>download</b> icon on the Cashier Accounting screen exports a CSV "
      "of all transactions for a date range you pick:"),
    ul([
        "<b>Download file</b> — saves to <code>Downloads/</code> on the "
        "device.",
        "<b>Email</b> — sends the CSV to one or more recipients you enter "
        "(remembered for next time).",
    ]),
    note("If a CSV Export Password has been set, you're asked for it before any "
         "export."),
]))

# ---------------------------------------------------------------------------
add("Inventory", "".join([
    p("<span class='role'>Admin / Supervisor</span> &nbsp; Dashboard → "
      "<b>Inventory</b>. Three tabs: <b>Products</b>, <b>Categories</b>, "
      "<b>Modifiers</b>."),
    h3("Products tab"),
    ul([
        "Search, filter by category chip, pull to refresh.",
        "<b>Add Product</b> (the + button) or tap a product to edit it.",
    ]),
    h4("The product form"),
    ul([
        "<b>Photo</b> — optional; pick from the device.",
        "<b>Name</b> and <b>Category</b> — both required.",
        "<b>Variants</b> — at least one is required. Each has a name and a "
        "price (min 0.01). Exactly one active variant is the <b>default</b>. "
        "Add as many as you need (Small / Medium / Large, etc.).",
        "<b>Modifier groups</b> — tick which modifier groups this product "
        "offers (e.g. “Add-ons”, “Sugar level”).",
    ]),
    note("Removing a variant that has never been sold deletes it; one that has "
         "sales is deactivated instead so past receipts and reports stay "
         "correct."),
    h3("Categories tab"),
    p("Create, rename, reorder and deactivate the categories that group your "
      "products and drive the category chips on the ordering screen."),
    h3("Modifiers tab"),
    p("Manage <b>modifier groups</b> and their <b>options</b>:"),
    ul([
        "A group has a <b>name</b>, a <b>Required</b> flag, and a <b>max "
        "selections</b> count (1 = choose one; more = multi-select).",
        "Each option has a <b>name</b> and an optional <b>added price</b> "
        "(e.g. “Extra cheese +20.00”).",
        "Attach groups to products from the product form (above).",
    ]),
    h3("Importing products from CSV"),
    p("<b>Settings → Import CSV → Products</b>. Expected columns "
      "(same format as the kiosk app):"),
    pre("Category, Category Description, Product Name, Product Description,\n"
        "Product Base Price, Variant Name, Variant Price, [Product Image URL]"),
    table(["Import mode", "Effect"], [
        ["<b>Add &amp; Update</b>",
         "Adds new products, updates existing ones by name. Nothing already in "
         "your menu is removed. (Default — safe.)"],
        ["<b>Replace Entire Menu</b>",
         "The file becomes your whole menu. Categories / products / variants "
         "not in the file are deleted (items with past sales are kept but "
         "disabled). Asks you to confirm first."],
    ]),
]))

# ---------------------------------------------------------------------------
add("Users", "".join([
    p("<span class='role'>Admin / Supervisor</span> &nbsp; Dashboard → "
      "<b>Users</b>. One card per staff member; a green / grey dot shows "
      "active / inactive."),
    h3("Add a user"),
    steps([
        "Tap <b>Add User</b>.",
        "Optionally choose a <b>photo</b>.",
        "Enter <b>Full Name</b> (required), and optionally Employee ID and "
        "Phone.",
        "Pick a <b>Role</b>: Cashier, Supervisor, or Admin.",
        "Tap <b>Add User</b>. They start on the default PIN and set their own on "
        "first sign-in.",
    ]),
    h3("Manage a user"),
    p("The &#8942; menu on each card:"),
    ul([
        "<b>Edit</b> — change name, role, photo, contact details, or the "
        "<b>Active</b> switch. An inactive user can't sign in and doesn't appear "
        "on the account grid.",
        "<b>Reset PIN</b> — back to the default; they set a new one next "
        "sign-in.",
        "<b>Delete</b> — permanent, can't be undone.",
    ]),
    note("Keep at least one working Admin account. If you lock yourself out, "
         "the only recovery is restoring a backup or a fresh install (which "
         "recreates the default Admin)."),
]))

# ---------------------------------------------------------------------------
add("Settings", "".join([
    table(["Setting", "What it does", "Who"], [
        ["<b>Import CSV</b>",
         "Bulk-load Products, Modifiers, Users, or Store Info from CSV files.",
         "<span class='role'>Admin</span>"],
        ["<b>Backup &amp; Restore</b>",
         "Make a backup now, or replace all device data from a backup file.",
         "<span class='role'>Admin</span>"],
        ["<b>CSV Export Password</b>",
         "Shows whether a password is required to download report CSVs. The "
         "password itself is set by IT in the app's configuration, not here.",
         "<span class='role'>Admin</span>"],
        ["<b>Store Information</b>",
         "Store ID, name, address, TIN, terminal name, payment methods, and the "
         "online-orders device registration status.",
         "<span class='role'>Admin</span>"],
        ["<b>Printer Setup</b>",
         "Find and connect a Bluetooth printer; test print / calibrate.",
         "Everyone"],
    ]),
    h3("Store Information fields"),
    table(["Field", "Notes"], [
        ["Store ID", "Unique code identifying the store to the online-orders "
         "service. Set once at first launch."],
        ["Store Name", "Required. Prints at the top of every receipt."],
        ["Address", "Prints on the receipt."],
        ["TIN", "Tax identification number; prints on the receipt."],
        ["Terminal Name", "A label for this device, e.g. “Front "
         "Counter”."],
        ["Payment Methods", "Add / edit / remove. Cash, GCash, and card have "
         "preset labels; “Other” lets you name your own. Non-cash "
         "methods can carry an account number."],
    ]),
]))

# ---------------------------------------------------------------------------
add("Backups", "".join([
    lead("The app protects your data automatically. You rarely need to touch "
         "this — but know how it works."),
    h3("Automatic backups"),
    ul([
        "A full backup (all data + product images, as a <code>.zip</code>) is "
        "written to <b>Downloads → POS Backups</b> roughly every "
        "<b>3 hours</b>.",
        "If nothing changed since the last one, it's skipped (no duplicate "
        "files).",
        "When the app is opened after being closed for a while, it runs a "
        "catch-up backup if the last one is more than 3 hours old.",
        "Backups older than <b>7 days</b> are deleted automatically.",
    ]),
    h3("Back Up Now"),
    p("<b>Settings → Backup &amp; Restore → Back Up Now</b> forces a "
      "fresh backup immediately. Do this before a big change (a menu replace, "
      "handing the device to someone else) or before you update the app."),
    h3("Restore Data"),
    note("Restoring <b>replaces everything</b> currently on the device with the "
         "contents of the backup file — all sales, products, users and "
         "settings. There is no merge.", "warn"),
    steps([
        "<b>Settings → Backup &amp; Restore → Restore Data</b>.",
        "<b>Choose backup file</b> and pick a <code>.zip</code> from Downloads / "
        "POS Backups (or wherever you copied one).",
        "Tap <b>Restore</b>, then confirm <b>Yes, Restore</b>.",
        "A safety backup of the <i>current</i> data is made first, then the "
        "restore runs. “Restore Complete” confirms it.",
    ]),
    h4("Moving to a new device"),
    ol([
        "On the old device: <b>Back Up Now</b>.",
        "Copy the newest <code>pos_backup_….zip</code> from Downloads / POS "
        "Backups to the new device (cable, cloud drive, email to yourself).",
        "On the new device: install the app, sign in as the default Admin, then "
        "<b>Restore Data</b> from that file.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Printer setup", "".join([
    lead("<b>Settings → Printer Setup.</b> Receipts print to an 80mm (or "
         "58mm) ESC/POS thermal printer over Bluetooth, or to a built-in printer "
         "if the device has one."),
    h3("Connect a Bluetooth printer"),
    steps([
        "Turn the printer on and make sure the phone's Bluetooth is on.",
        "Tap <b>Scan for Printers</b>. Grant the Bluetooth permission if asked. "
        "On some Android versions you may also be prompted to turn on Location "
        "or Bluetooth — the screen shows a button for each.",
        "Under <b>Paired devices</b> tap yours to connect, or under "
        "<b>Available devices</b> tap to pair then connect.",
        "“Connected to …” confirms it. The printer now shows under "
        "<b>Current Printer</b> with a green tick.",
    ]),
    p("<b>Remove</b> disconnects and forgets the saved printer."),
    h3("Calibration (only if receipts look wrong)"),
    ul([
        "<b>Print Calibration Ruler</b> — prints a numbered ruler. Note the "
        "last full number before the paper edge / wrap.",
        "<b>Print Width Probe</b> — prints lines <code>W=50</code>…"
        "<code>59</code>. Find the highest <code>W</code> whose <code>|</code> is "
        "still on the end of its line.",
        "Give those numbers to your IT / supplier so the receipt width can be "
        "corrected.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Daily routine", "".join([
    h4("Opening"),
    ul([
        "Sign in.",
        "Check the printer is on and connected (Settings → Printer Setup, "
        "or just print any receipt).",
        "If you use online orders, check the dashboard pill says <b>Live orders "
        "connected</b>.",
    ]),
    h4("During the shift"),
    ul([
        "Take sales through <b>New Order</b>.",
        "Watch <b>Orders</b> for online orders and move them along the status "
        "steps.",
        "Void mistakes from the receipt (needs a supervisor PIN).",
    ]),
    h4("Closing"),
    ul([
        "Each cashier: <b>Cashier Accounting → X-Reading → Close &amp; "
        "Print</b>, and <b>Daily Report → Close &amp; Print</b>.",
        "Supervisor / Admin: <b>Z-Reading → Close &amp; Print</b> "
        "(authorize with your PIN) for the store-wide close.",
        "Optionally export the day's transactions (download or email).",
        "<b>Sign Out</b>, or fully close the app.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Troubleshooting & FAQ", "".join([
    table(["Problem", "What to do"], [
        ["Can't sign in — “wrong PIN”",
         "Make sure the right account card is selected. An Admin / Supervisor "
         "can Reset PIN from Users."],
        ["Stuck on the “Set Your PIN” screen",
         "That account is on the default PIN. Choose a new 6-digit PIN (not "
         "000000) and confirm it — there's no way past it otherwise."],
        ["No products on the ordering screen",
         "Import a products CSV (Settings → Import CSV) or add products in "
         "Inventory. Also check the product / its variant is marked available."],
        ["“No payment methods configured”",
         "Admin: Settings → Store Information → Payment Methods → "
         "add at least one."],
        ["Receipt won't print",
         "Settings → Printer Setup: is a printer under “Current "
         "Printer”? Is it powered on and in range? Re-scan and reconnect. "
         "Try the calibration print."],
        ["Printer not found when scanning",
         "Turn Bluetooth off and on. Grant the Bluetooth permission (Open App "
         "Settings if it was permanently denied). On older Android, turn on "
         "Location Services."],
        ["Void button missing on a receipt",
         "The sale is already part of a closed X-Reading, Daily Report or "
         "Z-Reading and can no longer be voided."],
        ["“Live orders off” / Orders won't load",
         "Check internet. Check the device-registration status in Settings "
         "→ Store Information (it may be pending approval or rejected). "
         "Walk-in sales still work regardless."],
        ["Can't open Inventory / Users / some Settings",
         "Those are Admin / Supervisor only. Ask an admin, or sign in with an "
         "admin account."],
        ["Wrong totals in a reading",
         "Tap the refresh icon on that reading. X-Reading and Daily Report are "
         "per-cashier — make sure you're signed in as the right person."],
    ]),
    h3("Frequently asked"),
    h4("Does it need internet?"),
    p("No, except for the online <b>Orders</b> feed and one-time device "
      "registration. All selling, printing and reporting works offline."),
    h4("Where are my backups?"),
    p("On the device: <b>Downloads → POS Backups</b>, named "
      "<code>pos_backup_&lt;date&gt;.zip</code>. New one every ~3 hours, kept "
      "for 7 days."),
    h4("Can two people be signed in at once?"),
    p("No — one user at a time per device. Sign out (or close the app) to "
      "switch. Voids and Z-Readings let a supervisor authorize with their PIN "
      "without signing the cashier out."),
    h4("Can I refund part of a sale?"),
    p("This version supports a full <b>Void</b> of a transaction, not a partial "
      "line refund."),
]))
