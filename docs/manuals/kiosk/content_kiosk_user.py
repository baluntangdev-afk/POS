# -*- coding: utf-8 -*-
from manual_helpers import p, lead, h3, h4, steps, ol, ul, note, table, pre, join

SECTIONS = []
def S(title, *body): SECTIONS.append((title, "".join(body)))

# ---------------------------------------------------------------------------
S("Getting to know the system",
  lead("The POS Kiosk is a touch-screen point-of-sale for a single store lane. "
       "It runs on a Windows machine and is made of three parts that work together."),
  table(["Part", "What it is", "You interact with it?"], [
      ["Kiosk app", "The full-screen touch application on the counter (and, optionally, a second customer-facing screen).", "Yes \u2014 this whole manual."],
      ["Backend service", "A program running in the background on the same machine that stores products, sales, users and reports.", "No \u2014 it has no screen."],
      ["Database", "Where all the data physically lives (PostgreSQL).", "No."],
  ]),
  h3("User roles"),
  p("Every staff member has one role. The role decides which tiles appear on the main menu."),
  table(["Role", "Can do"], [
      ["Cashier <span class='role'>User</span>", "Take orders, accept payment, apply discounts, reprint / refund / void from Transactions, run X-Reading and cashier reports."],
      ["Supervisor", "Everything a cashier can do, plus authorise refunds and voids, manage products and users, close Z-Readings, run Backup &amp; Transfer."],
      ["Admin", "Everything. Full access to every tile, all settings and the terminal registration."],
  ]),
  note("A supervisor or admin PIN can be entered on the spot to approve a refund, a void or a "
       "report close \u2014 even when a cashier is the one signed in."),
  h3("What you need before first use"),
  ul([
      "The machine is powered on and connected to the same network / internet as usual.",
      "The POS Kiosk software has been installed by IT (services <code>POSBackendService</code> and <code>POSPostgres</code> are running).",
      "At least one <b>employee account</b> exists. On a brand-new install only the seeded admin exists \u2014 sign in as that admin first and add your real staff (Section 13).",
      "This terminal has been <b>registered</b> once with the store's legal name, address and TIN (Section 14).",
  ]))

# ---------------------------------------------------------------------------
S("Starting the kiosk and signing in",
  h3("2.1 Launch and start-up check"),
  steps([
      "Double-click the <b>POS Kiosk</b> shortcut on the desktop (in production it opens full-screen automatically).",
      "The start-up screen appears and checks that the backend is responding. This normally takes a few seconds.",
      "If it says <i>&ldquo;Services are taking a moment to start&hellip;&rdquo;</i> for more than ~20 seconds, wait \u2014 Windows may still be starting the background services. If it never clears, see Section 17.",
      "When the check passes you are taken to the <b>Welcome / Touch To Start</b> screen.",
  ]),
  h3("2.2 Sign in"),
  steps([
      "On the Welcome screen, tap <b>Touch To Start</b>.",
      "The <b>&ldquo;Who's working?&rdquo;</b> screen shows a tile for every active employee. Tap your name.",
      "Enter your <b>6-digit PIN</b> on the on-screen keypad. It submits automatically once the 6th digit is entered.",
      "If the PIN is wrong, a red message appears and the entry clears \u2014 try again.",
      "On success you land on the <b>main menu</b>, showing only the tiles your role allows.",
  ]),
  note("There is no username/password screen on the kiosk. Login is always <b>name + 6-digit PIN</b>. "
       "Email / User-ID login exists only in the backend API."),
  h3("2.3 First login \u2014 set your PIN"),
  p("New accounts (and accounts whose PIN was reset) are forced to choose a personal PIN before they can continue."),
  steps([
      "After entering the temporary PIN you will see <b>&ldquo;You need to change your PIN to continue&rdquo;</b>. Tap <b>Change PIN</b>.",
      "On <b>Create your PIN</b>, key in a new 6-digit PIN.",
      "On <b>Confirm your PIN</b>, key in the same 6 digits again. If they don't match you are asked to start over.",
      "You'll see <b>&ldquo;User PIN has been updated successfully. Please login again.&rdquo;</b> \u2014 sign in once more with your new PIN.",
  ]),
  note("The seeded admin account (name <b>Cody Admin</b>) ships with PIN <code>123456</code>. "
       "Change it immediately on first login.", kind="warn"))

# ---------------------------------------------------------------------------
S("The main menu",
  lead("The main menu is your home base. Tap a tile to open that module; tap <b>Sign Out</b> "
       "(top corner) to return to the login screen."),
  table(["Tile", "Opens", "Roles"], [
      ["New Order", "The ordering screen to build and check out a sale.", "All"],
      ["Orders", "The live board of online / channel orders. A badge shows how many are still pending.", "All"],
      ["Transactions", "History of completed sales; also the launch point for X-Reading, Cashier Daily Report, Z-Reading and report history.", "All"],
      ["Inventory", "&ldquo;Inventory Management&rdquo; \u2014 products, variants and categories.", "Supervisor, Admin"],
      ["Promos", "Reserved for a future promotions screen (no action yet).", "Supervisor, Admin"],
      ["Settings", "POS terminal details and payment methods for this lane.", "Supervisor, Admin"],
      ["User", "Employee accounts \u2014 add, edit, reset PIN, delete.", "Supervisor, Admin"],
      ["Sync Data", "Reserved for a future manual data-sync action (no action yet).", "Supervisor, Admin"],
      ["Backup &amp; Transfer", "Export the whole device to a file, or restore it onto a replacement machine.", "Supervisor, Admin"],
  ]),
  note("If you sign in and see <b>&ldquo;No POS Terminal Assigned&rdquo;</b>, <b>&ldquo;No Employees Added&rdquo;</b> "
       "or <b>&ldquo;No Products Found&rdquo;</b>, the system is guiding you through first-time setup \u2014 follow "
       "the button it offers (Register POS, Add Employee, Import Products) or <b>Skip for now</b>."))

# ---------------------------------------------------------------------------
S("Module: New Order \u2014 building a sale",
  lead("Opened from <b>New Order</b>. Left side is the product grid, right side is the running order."),
  h3("4.1 Find and add a product"),
  steps([
      "Use the <b>category chips</b> along the top to switch sections. Swipe or tap the arrows to see more chips.",
      "Tap a <b>product card</b>. The item-options dialog opens.",
      "If the product has <b>variants</b> (e.g. Small / Medium / Large), tap the one you want \u2014 the price updates.",
      "If the product has <b>modifier groups</b> (e.g. sugar level, add-ons), tap options to select them. Groups marked <i>&ldquo;Select 1&rdquo;</i> behave like radio buttons; <i>&ldquo;Select up to N&rdquo;</i> behave like check-boxes. The <b>Confirm</b> button stays disabled until every required group is satisfied.",
      "Set the <b>quantity</b> with the &minus; / + buttons.",
      "Tap <b>Confirm</b>. The line is added to the order panel on the right.",
  ]),
  h3("4.2 Work with the order panel"),
  ul([
      "Tap a line to expand it. From there you can change quantity, set the line's <b>Dine In / Take Out</b> type, add a <b>note</b> (e.g. &ldquo;no onions&rdquo;), or delete the line with the red bin icon.",
      "On the wide kiosk layout the panel is always visible on the right; on a narrow screen tap the <b>receipt / cart icon</b> in the header to slide it in.",
      "The footer shows the live breakdown: <b>VATable Sales</b>, <b>VAT-Exempt Sales</b> (if any), <b>VAT</b>, <b>Discount</b> (if any) and <b>Total</b>.",
      "A line that already has a discount is locked for quantity edits \u2014 remove the discount first (Section 5) to change it.",
  ]),
  h3("4.3 Move to payment"),
  steps([
      "Optionally tap <b>Apply Discount</b> (see Section 5).",
      "Tap <b>Proceed to Checkout / Proceed to Payment</b>. The button is greyed out until the order has at least one line.",
      "On tablet/phone layouts an <b>Order Summary</b> step is shown first; on the kiosk layout you go straight to the payment screen.",
  ]))

# ---------------------------------------------------------------------------
S("Module: Apply Discount",
  lead("Reached from the <b>Apply Discount</b> button on the order panel, the cart, or the checkout. "
       "Two discount types are supported."),
  table(["Type", "Use for", "Extra info required"], [
      ["Senior / PWD", "Government-mandated senior citizen and person-with-disability discount. Removes VAT on the chosen items and applies the statutory percentage.", "ID Number and Name of ID Holder."],
      ["Promo", "A promotional / manual discount.", "Promo Code."],
  ]),
  h3("5.1 Apply a discount"),
  steps([
      "Tap <b>Apply Discount</b>. The discount screen (or dialog) opens with your order items on one side and the discount controls on the other.",
      "Tick the <b>items</b> the discount should cover. Use <b>Select All / Deselect All</b> for the whole order. For a line with quantity &gt; 1 you can choose how many units are covered with the stepper (&ldquo;3 of 5&rdquo;).",
      "Choose the <b>discount type</b> (Senior/PWD or Promo).",
      "Fill in the required field(s): <b>ID Number</b> + <b>Name of ID Holder</b> for Senior/PWD, or <b>Promo Code</b> for Promo.",
      "Review the summary (Selected Total, VAT Exempt, Discount).",
      "Tap <b>Apply Discount</b>. Discounted lines show a <b>&ldquo;LESS: &hellip;&rdquo;</b> / <b>Discounted</b> badge back on the order.",
  ]),
  h3("5.2 Remove a discount"),
  ul([
      "On the order panel or cart, tap the <b>&ldquo;LESS: &hellip;&rdquo;</b> / <b>Discounted</b> badge (or its &times;) on the line to clear that line's discount.",
      "In the discount dialog, items already discounted appear grouped by beneficiary with a <b>Remove</b> button that clears the whole beneficiary group at once.",
  ]),
  note("Items that already carry a discount are shown locked in the picker so the same discount "
       "can't be stacked twice."))

# ---------------------------------------------------------------------------
S("Module: Checkout & Payment",
  h3("6.1 Take payment"),
  steps([
      "The payment screen lists the <b>Order Total</b> and the VAT breakdown on one side and the <b>payment methods</b> configured for this terminal on the other.",
      "Tap the method the customer is using (e.g. <b>Cash</b>, <b>Credit / Debit Card</b>, or an e-wallet).",
      "For <b>Cash</b>: enter the <b>amount tendered</b> on the keypad. The system shows the <b>change</b> due automatically.",
      "For <b>Card</b>: enter the <b>reference number</b> and the <b>last 4 digits of the card</b>.",
      "For an <b>e-wallet / QR</b> method: enter the <b>reference number</b> from the customer's payment confirmation.",
      "Tap <b>Confirm Payment</b>. While it processes the button shows <i>Processing&hellip;</i>",
      "On success the <b>receipt</b> screen appears.",
  ]),
  note("Tapping <b>Back</b> during payment asks <b>&ldquo;Cancel Payment?&rdquo;</b> \u2014 choose <b>Stay</b> to keep going "
       "or <b>Cancel Payment</b> to return to the order without charging."),
  h3("6.2 Receipt"),
  ul([
      "The receipt screen shows the store header (legal name, address, TIN, terminal serial number), the line items, totals and the payment.",
      "Use the on-screen action to <b>print</b> the receipt to the connected ESC/POS printer.",
      "Finishing the receipt returns you to a fresh <b>New Order</b>.",
  ]))

# ---------------------------------------------------------------------------
S("Module: Orders (channel / online orders)",
  lead("Opened from <b>Orders</b>. This is a live board of orders that arrive from outside the kiosk "
       "(online ordering, delivery apps, etc.). The main-menu tile carries a badge with the pending count."),
  h3("7.1 Read the board"),
  ul([
      "Orders are shown as cards in a <b>kanban board</b> with columns <b>Pending &rarr; Preparing &rarr; Fulfilled</b>, plus <b>Cancelled</b>.",
      "The filter row at the top narrows by fulfilment type: <b>All</b>, <b>On-Site</b>, <b>Pickup</b>, <b>Delivery</b>, <b>Other</b>.",
      "Each column footer shows a running <b>Total</b>. An empty column reads &ldquo;No &hellip; orders yet&rdquo;.",
      "New orders appear automatically as they come in \u2014 no need to refresh.",
  ]),
  h3("7.2 Act on an order"),
  steps([
      "Tap a card to open <b>order items</b> and see the full contents and total.",
      "Advance an order to the next stage using its card control as each step is done.",
      "To cancel one order, use the card's cancel action and confirm <b>&ldquo;Cancel this order?&rdquo;</b> &rarr; <b>Cancel order</b>.",
      "To clear the whole board, use <b>Delete all orders</b> in the header and confirm <b>&ldquo;Delete all orders?&rdquo;</b> &rarr; <b>Delete all</b>.",
  ]),
  note("<b>Delete all orders</b> is destructive and cannot be undone. Use it only for a genuine reset "
       "(e.g. end of a test period).", kind="warn"))

# ---------------------------------------------------------------------------
S("Module: Transactions",
  lead("Opened from <b>Transactions</b>. A searchable, sortable, paged table of completed sales, and the "
       "gateway to all cashier reports."),
  h3("8.1 Find a sale"),
  ul([
      "Columns: <b>Invoice #</b>, <b>Cashier</b>, <b>Date</b>, <b>Time</b>, <b>Total</b>, <b>Actions</b>.",
      "Tap the <b>Date</b> header to sort; use <b>Previous</b> / <b>Next</b> to page through results.",
  ]),
  h3("8.2 Reprint a receipt"),
  steps([
      "Find the sale in the table.",
      "Tap <b>Reprint</b> in its Actions cell. The original receipt is sent to the printer again.",
  ]),
  h3("8.3 Refund a sale"),
  steps([
      "Tap <b>Refund</b> on the sale's row. The <b>Process Refund</b> screen opens.",
      "Select the item(s) and quantities to refund (full or partial).",
      "Enter a <b>Reason for Refund</b>.",
      "When prompted with <b>&ldquo;Authorization Required&rdquo;</b>, a Supervisor or Admin enters their PIN.",
      "Confirm. You'll see <b>&ldquo;Refund Processed&rdquo;</b> and the refund is recorded against the sale.",
  ]),
  h3("8.4 Void a sale"),
  steps([
      "Tap <b>Void</b> on the sale's row.",
      "Enter a <b>Reason for Void</b>.",
      "A Supervisor or Admin authorises with their PIN.",
      "Confirm. You'll see <b>&ldquo;Transaction Voided&rdquo;</b> and the sale's status changes to Voided.",
  ]),
  note("A voided sale cannot be un-voided. Check the invoice and amount before authorising.", kind="warn"))

# ---------------------------------------------------------------------------
S("Module: X-Reading & Cashier Daily Report",
  lead("Both are opened from buttons in the <b>Transactions</b> header. They summarise <i>your own</i> "
       "sales on <i>this terminal</i> for <i>today</i>."),
  h3("9.1 X-Reading (mid-shift read)"),
  steps([
      "In Transactions, tap <b>X-Reading</b>. The current figures load and the X-Reading screen opens.",
      "Review: Sales Summary (Total Sales, Average / Highest / Lowest Sale), Transaction Summary (Completed, Refunded), Discount Summary, Tax Summary, Cash Collected, Total Qty Sold.",
      "Tap <b>Print X-Reading</b> to print a copy. This does <b>not</b> close the shift \u2014 you can run an X-Reading as often as you like.",
  ]),
  h3("9.2 Cashier Daily Report"),
  steps([
      "In Transactions, tap <b>Cashier Daily Report</b>.",
      "Review the BIR-style breakdown: Gross Sales, Vatable / Zero-Rated Sales, Net of Tax, No. Transactions, Total Quantity, Cash Sales, Sales by Product, and the Cash Ledger.",
      "Tap <b>Print Cashier Report</b>.",
      "To close the day's cashier report, use the close action and authorise if prompted. Closing files it into report history.",
  ]),
  note("&ldquo;Close&rdquo; on a report finalises that day's numbers and moves the report into history "
       "(Section 11). Print first if you need a paper copy."))

# ---------------------------------------------------------------------------
S("Module: Z-Reading (end of day)",
  lead("Opened from the <b>Z-Reading</b> button in the Transactions header. The Z-Reading is the "
       "store-wide end-of-day close and is authorised."),
  h3("10.1 Run and close a Z-Reading"),
  steps([
      "In Transactions, tap <b>Z-Reading</b>. Current store-wide figures load.",
      "Review the full report: Grand Total (Beginning / Ending Balance), Sales Summary, Qty &times; Product, Transaction Summary (Completed / Refunded), Discount Summary, Tax Summary, Cash Collected, Total Qty Sold and <b>Sales by Cashier</b>.",
      "Tap <b>Print Z-Reading</b> for the paper copy.",
      "To close: use the close action. The <b>&ldquo;Z-Reading Close Authorization&rdquo;</b> dialog appears \u2014 a Supervisor or Admin enters their PIN and taps <b>Authorize Close</b>.",
      "After closing, the Z counter advances and the report is stored in history with the names of who closed and who authorised it.",
  ]),
  note("Close the Z-Reading once per business day, after the last sale. It cannot be re-opened.", kind="warn"),
  h4("Reprint"),
  p("A closed Z-Reading can be reprinted from its screen with <b>Reprint Z-Reading</b>, or later from report history."))

# ---------------------------------------------------------------------------
S("Module: Report history",
  lead("Opened with the <b>Reports</b> button in the Transactions header. Lets you look up and reprint "
       "reports that were closed earlier."),
  steps([
      "Tap <b>Reports</b>. The history screen opens with three tabs: <b>X-Reading</b>, <b>Cashier Daily Report</b>, <b>Z-Reading</b>.",
      "Pick a tab. Closed reports are listed newest first, paged (&ldquo;Page X of Y&rdquo;). Empty tabs read &ldquo;No closed &hellip; yet&rdquo;.",
      "Tap a row to open that historical report exactly as it was closed.",
      "Use the <b>Reprint</b> action on the opened report to print another copy.",
  ]))

# ---------------------------------------------------------------------------
S("Module: Inventory Management (products & categories)",
  lead("Opened from <b>Inventory</b>. Despite the name this is your <b>product catalogue</b> editor. It has "
       "two tabs: <b>Products</b> and <b>Categories</b>."),
  h3("12.1 Categories tab"),
  steps([
      "Open <b>Inventory &rarr; Categories</b>.",
      "Tap <b>Add Category</b>. Enter a <b>Name</b>, an optional <b>Description</b>, and set the <b>Active</b> toggle.",
      "Tap <b>Save</b>.",
      "For an existing category use the row menu: <b>Edit</b>, or <b>Disable</b> / <b>Enable</b> (an inactive category and its products are hidden from the New Order screen).",
  ]),
  h3("12.2 Products tab \u2014 add a product"),
  steps([
      "Open <b>Inventory &rarr; Products</b> and tap <b>Add Product</b>.",
      "Enter the <b>Name</b>.",
      "Choose a <b>Category</b> (required).",
      "Optionally add an <b>Image</b> (&ldquo;Image (optional)&rdquo; / &ldquo;Replace Image&rdquo;).",
      "Add at least one <b>Variant</b>: tap <b>Add Variant</b>, give it a name (e.g. &ldquo;Regular&rdquo;, &ldquo;Venti&rdquo;) and a price of at least 0.01. Mark one variant as the <b>default</b> (star). Disable a variant to hide it without deleting.",
      "Tap <b>Save</b>. The product appears immediately on the New Order screen (categories/products refresh each time that screen opens).",
  ]),
  h3("12.3 Edit / disable a product"),
  ul([
      "Search with the <b>Search products&hellip;</b> box or filter by category chip.",
      "Open a product to <b>Edit</b> its details, image and variants; tap <b>Update</b> to save.",
      "A product with no enabled variant shows a <b>Disabled</b> badge and won't sell.",
  ]),
  h3("12.4 Import products from CSV"),
  steps([
      "On the Products tab tap <b>Import CSV</b>.",
      "Tap <b>Download template</b> to get a correctly-formatted file. Columns: Category, Product Name, Variant Name, Price, and optionally Product Image URL.",
      "Choose the <b>import mode</b>: <b>Add &amp; Update (Upsert)</b> \u2014 nothing already in your menu is removed; or <b>Replace Entire Menu</b> \u2014 wipes the current menu first.",
      "Tap <b>Choose CSV file</b> and select your file.",
      "Tap <b>Import</b>. When it finishes you'll see an <b>Import Complete</b> summary.",
  ]),
  note("<b>Replace Entire Menu</b> asks <b>&ldquo;Replace Entire Menu?&rdquo;</b> &rarr; <b>Yes, Replace</b> and cannot be undone. "
       "Prefer <b>Upsert</b> unless you are deliberately rebuilding the catalogue.", kind="warn"))

# ---------------------------------------------------------------------------
S("Module: Modifier Groups",
  lead("Modifier groups are the add-on / choice lists attached to products (sugar level, extra shot, "
       "toppings). Managed from the <b>Modifier Groups</b> screen within Inventory."),
  h3("13.1 Create a modifier group"),
  steps([
      "Open <b>Modifier Groups</b> and tap <b>Create New Group</b>.",
      "Enter the <b>Group Name</b>.",
      "Set the <b>minimum</b> and <b>maximum</b> selections. Min&nbsp;1 / Max&nbsp;1 makes a required single-choice (radio) list; Min&nbsp;0 / Max&nbsp;3 makes an optional pick-up-to-three list.",
      "Add each option with <b>Add Modifier</b>: give it a name and an optional extra price.",
      "Save the group.",
  ]),
  h3("13.2 Assign, edit and delete"),
  ul([
      "The list shows each group's <b>Modifiers</b> count and <b>Used By</b> (how many products use it).",
      "<b>Edit Group</b> to rename it, change min/max, or add/remove options.",
      "Attach a group to a product from the product editor (Section 12).",
      "<b>Delete Group</b> removes it \u2014 do this only if no products still rely on it.",
  ]))

# ---------------------------------------------------------------------------
S("Module: User (employee accounts)",
  lead("Opened from <b>User</b>. Add and maintain the staff who can sign in to this kiosk."),
  h3("14.1 The list"),
  ul([
      "Stat cards across the top: <b>Total Users</b>, <b>Admins</b>, <b>Supervisors</b>, <b>Users</b>.",
      "Search by <b>name, email, or ID</b>; filter by role with the <b>All Roles</b> selector.",
  ]),
  h3("14.2 Add an employee"),
  steps([
      "Tap <b>Add User</b>.",
      "<b>Personal Information</b>: Employee ID (required), First Name (required), Middle Name, Last Name (required).",
      "<b>Contact Details</b>: Phone Number (validated).",
      "<b>Account Settings</b>: set <b>Status</b> (Active / Cancelled) and <b>User Type</b> (User, Supervisor, Admin).",
      "Tap <b>Create User</b>. You'll see <b>&ldquo;User has been created successfully.&rdquo;</b>",
  ]),
  note("New employees receive the default PIN and are forced to set their own on first sign-in (Section 2.3). "
       "The default kiosk PIN is <code>123456</code> unless your installer changed it."),
  h3("14.3 Edit, reset PIN, delete"),
  ul([
      "<b>Edit</b> a row to update details or change the role/status, then <b>Update User</b>.",
      "<b>Reset Pin</b> (in the edit dialog) puts the account back to the default PIN and forces a new one at next login \u2014 use this when someone forgets their PIN.",
      "<b>Delete</b> removes the account (confirm in the <b>Delete User</b> dialog). Their past sales stay in history but they can no longer sign in.",
  ]))

# ---------------------------------------------------------------------------
S("Module: Settings \u2014 terminal & payment methods",
  lead("Opened from <b>Settings</b>. Holds the identity of this lane and the payment methods it offers. "
       "On a brand-new machine you register the terminal here first."),
  h3("15.1 Register this terminal (first time only)"),
  steps([
      "If the menu shows <b>&ldquo;No POS Terminal Assigned&rdquo;</b>, tap <b>Register POS</b> (or open Settings).",
      "On <b>Register POS Terminal</b> enter the store's <b>Legal Name</b>, <b>Address</b> and <b>TIN Number</b>.",
      "Add the <b>Payment Methods</b> you will accept (see 15.3).",
      "Tap <b>Register Terminal</b>.",
  ]),
  h3("15.2 View / edit terminal details"),
  steps([
      "Open <b>Settings</b>. The dialog shows <b>&ldquo;View and edit your terminal information.&rdquo;</b>",
      "Edit <b>Legal Name</b>, <b>Address</b>, <b>TIN Number</b> as needed \u2014 these print on every receipt and report.",
      "The <b>Kiosk ID</b> is shown here (with a copy button). It is the number that appears in every invoice number, e.g. <code>SO-001-2026-0001</code>.",
      "Tap <b>Save Changes</b>.",
  ]),
  h3("15.3 Payment methods"),
  steps([
      "In the terminal dialog, under <b>Payment Methods</b>, tap <b>Add Payment Method</b>.",
      "Enter the <b>Payment Method Name</b> (e.g. Cash, Credit Card, GCash) and an optional <b>Payment Number</b> (account / merchant number for e-wallets).",
      "Save. The method now appears on the payment screen.",
      "Use <b>Edit</b> / remove on a method to change or retire it.",
  ]),
  note("Only methods named exactly <b>Cash</b> and <b>Credit Card</b> get the special cash-tendered and "
       "card-reference input flows; any other name is treated as a reference-number (e-wallet) method."))

# ---------------------------------------------------------------------------
S("Module: Backup & Transfer",
  lead("Opened from <b>Backup &amp; Transfer</b>. Moves this device's <b>entire</b> dataset \u2014 staff and PINs, "
       "products, every sale, payment, refund and report \u2014 to a replacement machine. Admin / Supervisor only."),
  h3("16.1 Export a backup (on the OLD machine)"),
  steps([
      "Open <b>Backup &amp; Transfer &rarr; Export Backup &rarr; Start Export</b>.",
      "Enter and <b>confirm a passphrase</b> (at least 12 characters). Write it down \u2014 the file is useless without it and it cannot be recovered.",
      "Authorise with a <b>Supervisor PIN</b> when prompted (<b>Authorize Export</b>).",
      "Choose where to save <code>pos-kiosk-backup-&lt;date&gt;.posbackup</code> (e.g. a USB drive).",
      "Wait for <b>&ldquo;Backup Saved&rdquo;</b>. Treat the file like a list of everyone's PINs \u2014 it contains them (encrypted).",
  ]),
  note("Exporting does not change the old machine. Keep trading on it until the new one is ready."),
  h3("16.2 Import & restore (on the NEW machine)"),
  steps([
      "Install the POS software on the new machine and let it reach the login screen once.",
      "Sign in as Admin/Supervisor (use the seeded admin if no staff exist yet).",
      "Open <b>Backup &amp; Transfer &rarr; Import &amp; Restore &rarr; Start Restore</b>.",
      "<b>Choose backup file (.posbackup)</b>, enter the <b>passphrase</b>, and type <code>REPLACE</code> in the confirmation box.",
      "Authorise with a <b>Supervisor PIN</b> (<b>Authorize Restore</b>), then tap <b>Replace All Data</b>.",
      "Wait for <b>&ldquo;Restore Complete&rdquo;</b> \u2014 <b>do not close the app while it runs</b>. You are signed out automatically; sign back in with the credentials from the old machine.",
  ]),
  h3("16.3 &ldquo;Incompatible Backup&rdquo; / Partial restore"),
  p("If the two machines are on different app versions you'll see <b>&ldquo;Incompatible Backup&rdquo;</b>. "
    "The best fix is to update both to the same version and export again. If that isn't possible, "
    "tick <b>Partial restore</b> \u2014 only the data both versions have in common is imported, and a "
    "summary lists what was skipped."),
  note("A restore wipes whatever is on the new machine and replaces it with the backup, including "
       "receipt / official-receipt sequence numbers. Only run it on a fresh replacement device.", kind="warn"))

# ---------------------------------------------------------------------------
S("Customer display (second screen)",
  lead("If a second monitor is connected, the kiosk automatically opens a customer-facing display on it. "
       "It needs no operation \u2014 it mirrors what the cashier is doing."),
  ul([
      "<b>Idle</b>: a rotating showcase of menu items.",
      "<b>During an order</b>: the live list of items and the running total the customer is being charged.",
      "<b>After payment</b>: a thank-you screen, then back to idle.",
  ]),
  note("The customer display picks the non-primary monitor automatically. If it appears on the wrong "
       "screen, swap the monitor cables or set the correct primary display in Windows, then restart the app."))

# ---------------------------------------------------------------------------
S("Signing out & switching users",
  steps([
      "From the main menu tap <b>Sign Out</b> (top corner, logout icon).",
      "You return to the <b>&ldquo;Who's working?&rdquo;</b> screen.",
      "The next person taps their name and enters their PIN.",
  ]),
  note("Always sign out at the end of your shift so sales and X/Z readings are attributed to the right "
       "cashier. Run your <b>Cashier Daily Report</b> / <b>X-Reading</b> before handing over."))

# ---------------------------------------------------------------------------
S("Troubleshooting",
  table(["Symptom", "What to do"], [
      ["Stuck on the start-up screen / &ldquo;Services are taking a moment&rdquo;",
       "Wait up to a minute. If it persists, ask IT to run <code>recover-services.bat</code> as administrator from <code>C:\\POSKiosk\\scripts\\</code>, or restart the machine."],
      ["&ldquo;Could not load products&rdquo; on New Order",
       "Tap <b>Retry</b>. If it keeps failing, the backend or network is down \u2014 see the row above."],
      ["A product isn't on the New Order screen",
       "Check in Inventory that it has an <b>enabled variant</b> and that its <b>category is Active</b>. Re-open New Order to force a refresh."],
      ["No <b>Refund</b> / <b>Void</b> buttons",
       "Those need a Supervisor or Admin. Ask one to authorise, or sign in with the right role."],
      ["Receipt won't print",
       "Check the printer is on, has paper and is connected. Confirm the terminal's printer settings."],
      ["&ldquo;Internal server error&rdquo; when saving a sale / payment",
       "The kiosk number file may be missing. Ask IT to check <code>C:\\POSKiosk\\settings.txt</code> contains <code>kiosk.no=&lt;n&gt;</code> and restart <code>POSBackendService</code>."],
      ["Reports show no data",
       "Make sure the date really has completed sales and that this terminal is registered (Section 15)."],
      ["Customer display on the wrong monitor",
       "Fix the Windows primary-display setting or monitor cabling, then restart the app."],
  ]))

# ---------------------------------------------------------------------------
S("Quick reference by role",
  h4("Cashier (User)"),
  ul(["New Order &rarr; Payment &rarr; Receipt", "Orders board", "Transactions: Reprint; Refund &amp; Void (needs supervisor PIN)",
      "X-Reading, Cashier Daily Report", "Sign out at end of shift"]),
  h4("Supervisor"),
  ul(["Everything a cashier can do", "Authorise refunds, voids and Z-Reading closes", "Inventory: products, variants, categories, CSV import, modifier groups",
      "User: add / edit / reset PIN / delete staff", "Settings: terminal details &amp; payment methods", "Backup &amp; Transfer"]),
  h4("Admin"),
  ul(["Full access to every tile and setting", "Register / re-configure the POS terminal", "First-time setup: add staff, import products, register terminal"]),
  h4("Daily rhythm"),
  ol(["Sign in", "Take orders through the day", "Run X-Readings / Cashier Daily Report as needed",
      "After the last sale: print &amp; close the Z-Reading (supervisor authorises)", "Sign out"]))
