# -*- coding: utf-8 -*-
"""User-manual content for Cartivo Merchant. Plain-language, step-by-step."""

from manual_helpers import p, lead, h3, h4, ul, ol, steps, note, table, pre

SECTIONS = []


def add(title, body):
    SECTIONS.append((title, body))


# ---------------------------------------------------------------------------
add("About Cartivo Merchant", "".join([
    lead("Cartivo Merchant (shown on the device as <b>Cartivo Merchant</b>, and "
         "titled <b>DPO Merchant</b> in some builds) is a companion app for "
         "third-party merchants who sell through the Cartivo / DPO platform. Its "
         "one job is to put every online order for your store in front of your "
         "staff the moment it is placed, and to let them move that order through "
         "to completion."),
    h3("What the app does"),
    ul([
        "<b>Shows your live order feed.</b> New orders from your storefront "
        "appear on the screen within a second, with a sound / banner alert.",
        "<b>Lets you work each order.</b> Move an order from <i>Pending</i> to "
        "<i>Preparing</i> to <i>Ready</i> to <i>Fulfilled</i>, or cancel it.",
        "<b>Keeps a local copy.</b> The orders you have already received are "
        "stored on the device, so the list still opens when the connection "
        "drops — you just can't receive new ones until it comes back.",
        "<b>Alerts you in the background.</b> A phone notification fires for "
        "every new or changed order even when the app is not the screen you are "
        "looking at.",
    ]),
    h3("What the app does NOT do"),
    ul([
        "It is <b>not</b> a point-of-sale / cash register. It does not ring up "
        "walk-in sales, take payment, or print receipts.",
        "It has <b>no product catalogue, no inventory, and no reports.</b> "
        "Those live in the main Cartivo POS.",
        "It has <b>no user accounts or PINs.</b> Anyone holding the unlocked "
        "device can work the order list. Treat the device accordingly.",
    ]),
    h3("The one thing to understand: this app needs the internet"),
    p("Unlike the full Cartivo POS, this app does almost nothing offline. The "
      "live feed, order updates, and first-time setup all need a working "
      "Wi-Fi or mobile-data connection. Offline, you can only <i>read</i> the "
      "orders already downloaded."),
    note("Keep the device on a stable connection during trading hours. The "
         "app reconnects on its own after a brief drop, but a long outage "
         "means missed orders.", "warn"),
]))

# ---------------------------------------------------------------------------
add("Before you start", "".join([
    h3("What you need"),
    ul([
        "An <b>Android phone or tablet</b> (Android 8 / 2017 or newer "
        "recommended; the app targets modern Android). iPhone / iPad is not "
        "supported.",
        "The <b>Cartivo Merchant app</b> installed. Your IT person or provider "
        "builds and installs it — see the Technical Manual.",
        "A <b>Wi-Fi or mobile-data</b> connection.",
        "Your <b>Merchant ID</b> and <b>Merchant Name</b>, as issued by your "
        "Cartivo / DPO provider. If you were not given a Merchant ID, the app "
        "can generate one for you to hand back to your provider.",
        "Someone on the <b>merchant administrator</b> side who can approve this "
        "device (see “Getting your device approved”).",
    ]),
    h3("How the app is laid out"),
    p("There is only one screen: the <b>dashboard</b>. Everything happens "
      "there — a thin toolbar across the top, and the order list filling "
      "the rest. Setup prompts appear as pop-up dialogs over that screen."),
    table(["Area", "What it is"], [
        ["Top-left", "The <b>Cartivo</b> wordmark, and — once you are set "
         "up — your <i>Merchant Name | Merchant ID</i> underneath it."],
        ["Top-right", "The device-status icon (only while not yet approved), "
         "the live-connection pill, and the <b>Settings</b> gear."],
        ["Below the toolbar", "The <b>Orders</b> heading, a <b>Refresh</b> "
         "link, and a row of filter tabs (<i>All</i>, plus one per status)."],
        ["Main area", "The list of order cards, newest first. Pull down to "
         "refresh."],
    ]),
]))

# ---------------------------------------------------------------------------
add("First-time setup — registering your merchant", "".join([
    lead("The very first time the app opens with no merchant saved, it puts a "
         "<b>Register Merchant</b> dialog on screen that you cannot dismiss "
         "until it is filled in. This happens once per device."),
    steps([
        "Open the app. The <b>Register Merchant</b> dialog appears.",
        "Check the <b>Merchant ID</b> field. The app has pre-filled a random "
        "10-character ID. If your provider gave you an ID, delete the "
        "pre-filled one and type theirs exactly. If not, keep the generated "
        "one and pass it to your provider so they can register your store on "
        "their side.",
        "Type your <b>Merchant Name</b> — your store's name as you want "
        "it to read (for example <i>Juan's Store</i>).",
        "Tap <b>Register</b>. The button shows a spinner while the app talks "
        "to the server.",
        "If the details are accepted, the dialog closes and the app moves "
        "straight to checking whether this device is approved (next section).",
        "If you see a red error message instead, read it, fix the field it "
        "points to (usually a wrong Merchant ID or no connection), and tap "
        "<b>Register</b> again.",
    ]),
    note("The Merchant ID and Name you enter here are also what your provider "
         "sees. They must match what the provider has on file, or orders will "
         "never reach this device.", "warn"),
    h3("What “registering” actually does"),
    p("Two things happen behind that one <b>Register</b> tap:"),
    ul([
        "The app asks the server for a security token tied to your Merchant "
        "ID.",
        "The app then <b>enrols this physical device</b> under your merchant "
        "account, sending a fingerprint of the device (its model, Android "
        "version, and a permanent install ID). The device starts life "
        "<i>pending</i> — it is not yet allowed to receive orders.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Getting your device approved", "".join([
    lead("A newly registered device is <b>Pending</b>. It can open the app and "
         "show past orders, but the live feed stays switched off until a "
         "merchant administrator approves it from their side. You cannot "
         "approve your own device."),
    h3("The three device states"),
    table(["State", "Icon in toolbar", "What it means"], [
        ["<b>Pending</b>", "Amber hourglass",
         "Submitted, waiting for the administrator. Live orders are off. You "
         "may keep using the app."],
        ["<b>Approved</b>", "(icon disappears)",
         "The device is cleared. Live orders turn on automatically — no "
         "restart needed."],
        ["<b>Deactivated</b>", "Red block / no-entry",
         "The administrator has turned this device's access off. Live orders "
         "are paused. Contact your administrator to restore it."],
    ]),
    h3("While you wait"),
    steps([
        "A <b>Device Pending Approval</b> dialog explains the status. Tap "
        "<b>Got it</b> to dismiss it — you can keep the app open.",
        "Ask your merchant administrator to approve the device (they do this "
        "in their own Cartivo admin tools).",
        "You do <b>not</b> need to do anything else. The app quietly "
        "re-checks every 15 seconds, and again each time you bring it back to "
        "the foreground. The moment approval lands, the amber icon vanishes, "
        "a green <b>“Device approved — you're all set”</b> "
        "banner appears, and the connection pill turns to <b>Live</b>.",
    ]),
    h3("Checking manually"),
    p("If you don't want to wait for the automatic check:"),
    ul([
        "Tap the <b>amber hourglass icon</b> in the toolbar, then tap "
        "<b>Check again</b> in the dialog. The button spins while it "
        "re-checks and reports the fresh result.",
        "Or open <b>Settings</b> (the gear) — the card at the top of that "
        "screen shows the current device status and has its own <b>Check "
        "status</b> button.",
    ]),
    note("If the dialog shows a note from your administrator (a “review "
         "note”), read it — it usually says what they still need "
         "from you before approving.", "note"),
]))

# ---------------------------------------------------------------------------
add("The dashboard toolbar", "".join([
    lead("The strip across the top of the screen is always visible. Here is "
         "every control on it, left to right."),
    table(["Control", "What it does"], [
        ["<b>Cartivo</b> wordmark + store line",
         "Identifies the app and, underneath, shows <i>your Merchant Name | "
         "your Merchant ID</i> once set up. Read-only."],
        ["<b>Device-status icon</b> (amber hourglass or red block)",
         "Only shown while the device is <i>not</i> approved. Tap it to "
         "re-open the status dialog and re-check."],
        ["<b>Connection pill</b>",
         "The state of the live order feed. See the table below. On a narrow "
         "phone screen it shrinks to just a coloured dot."],
        ["<b>Settings</b> gear",
         "Opens <b>Merchant Settings</b> — edit your store name / ID and "
         "see the device-status card."],
    ]),
    h3("Reading the connection pill"),
    table(["Pill", "Colour", "Meaning"], [
        ["<b>Live</b>", "Green", "Connected. New orders will arrive instantly."],
        ["<b>Connecting</b>", "Amber (pulsing)",
         "Establishing the connection — normal for a few seconds after "
         "opening the app."],
        ["<b>Reconnecting</b>", "Amber (pulsing)",
         "The connection dropped and the app is retrying. It backs off "
         "gradually and keeps trying — usually recovers on its own."],
        ["<b>Offline</b>", "Grey",
         "Not connected and not trying — because there is no merchant "
         "set up, the device isn't approved, or it was deactivated."],
    ]),
    note("A short spell of <b>Reconnecting</b> is nothing to worry about — "
         "the app replays any orders you missed as soon as it is back. If it "
         "stays on <b>Reconnecting</b> for minutes, check the device's "
         "internet.", "note"),
]))

# ---------------------------------------------------------------------------
add("The Orders list", "".join([
    lead("The main area is the order list — one card per order, most "
         "recent at the top. It updates itself as orders arrive and change."),
    h3("The filter tabs"),
    ul([
        "<b>All</b> is selected by default and shows every order.",
        "Extra tabs appear automatically, one for each status that currently "
        "has orders — <i>Pending</i>, <i>Preparing</i>, <i>Ready</i>, "
        "<i>Fulfilled</i>, <i>Cancelled</i>. Each tab shows a count.",
        "Tap a tab to show only that status. If a tab empties out (its last "
        "order moved on), the view falls back to <b>All</b>.",
    ]),
    h3("What one order card shows"),
    ul([
        "<b>Order #</b> and its <b>status pill</b> (tap the pill to change "
        "status — see the next section).",
        "A subtitle line: the customer name (or <i>Guest</i>), and how the "
        "order is handed over — <i>On-site</i> (with the facility name), "
        "<i>Pickup</i>, or <i>Delivery</i>.",
        "A relative time — <i>just now</i>, <i>5m ago</i>, <i>2h ago</i>.",
        "The <b>line items</b> — quantity, product name, and line price.",
        "The <b>Total</b>, in your storefront's currency (shown with a "
        "₱ symbol).",
        "A <b>CANCEL ORDER</b> button, unless the order is already "
        "<i>Fulfilled</i> or <i>Cancelled</i>.",
    ]),
    h3("Refreshing the list"),
    ul([
        "The list refreshes itself on every live event. You rarely need to.",
        "To force a full re-fetch from the server: tap the <b>Refresh</b> "
        "link next to the <i>Orders</i> heading, or <b>pull down</b> on the "
        "list.",
        "If a refresh fails (no connection), a red <b>“Couldn't refresh "
        "— showing cached data”</b> banner appears with a "
        "<b>Retry</b> link. The list keeps showing the last data it had.",
    ]),
    h3("Empty and error states"),
    table(["You see", "It means"], [
        ["<b>“No orders yet”</b> with a receipt icon",
         "The current tab has no orders. Normal at the start of the day."],
        ["<b>“Couldn't load orders”</b> with a <b>Try Again</b> button",
         "The first load failed and there was no cached copy to fall back "
         "on. Check the connection and tap <b>Try Again</b>."],
    ]),
]))

# ---------------------------------------------------------------------------
add("Working an order — status flow", "".join([
    lead("The heart of the app: moving each order through its stages so the "
         "customer and your storefront can see progress."),
    h3("The stages"),
    table(["Status", "Colour", "Use it when"], [
        ["<b>Pending</b>", "Amber", "The order has just come in and nobody has "
         "started it. This is where new orders land."],
        ["<b>Preparing</b>", "Amber", "Someone has begun making the order."],
        ["<b>Ready</b>", "Green", "The order is finished and waiting for "
         "pickup / hand-off / the runner."],
        ["<b>Fulfilled</b>", "Teal", "The customer has received the order. "
         "This is the end state — the card locks."],
        ["<b>Cancelled</b>", "Red", "The order will not be completed. Also an "
         "end state — the card locks."],
    ]),
    h3("Changing the status"),
    steps([
        "On the order card, tap the <b>status pill</b> (top-right of the "
        "card). It has a small down-arrow to show it is tappable.",
        "A short menu drops down: <b>Pending</b>, <b>Preparing</b>, "
        "<b>Ready</b>, <b>Fulfilled</b>. The current status has a check "
        "mark.",
        "Tap the status you want. The pill shows a spinner while it saves.",
        "When it succeeds the pill updates and the change is pushed to your "
        "storefront. If it fails, a red message slides up from the bottom and "
        "the pill stays on the old status — try again.",
    ]),
    note("You can move an order in any direction (for example back from "
         "<i>Ready</i> to <i>Preparing</i>) while it is not yet fulfilled or "
         "cancelled. Once it is <b>Fulfilled</b> or <b>Cancelled</b> the pill "
         "is no longer tappable.", "note"),
    h3("Cancelling an order"),
    steps([
        "Tap the red <b>CANCEL ORDER</b> button at the bottom of the card.",
        "A confirmation asks <b>“Cancel this order?”</b> — it "
        "warns this can't be undone.",
        "Tap <b>Cancel order</b> to confirm, or <b>Keep order</b> to back "
        "out.",
        "On confirm, the order moves to <b>Cancelled</b>, the card locks, and "
        "your storefront is notified.",
    ]),
    h3("If another device changes the same order"),
    p("Orders are shared. If a colleague on another device (or your "
      "storefront) changes an order, this app receives that change on the "
      "live feed and updates the card by itself — you may see a pill "
      "change under your finger. The most recent change always wins."),
]))

# ---------------------------------------------------------------------------
add("Order details view", "".join([
    lead("Tap anywhere on an order card (except the status pill or the cancel "
         "button) to slide up a full, read-only detail sheet."),
    h3("What the detail sheet adds over the card"),
    ul([
        "The customer's <b>email address</b>, if the order carries one.",
        "The <b>district / delivery area name</b>, if present.",
        "Each line item with its <b>unit price</b> (“₱x each”) "
        "as well as the line total.",
        "A clear <b>Total</b> at the bottom.",
    ]),
    steps([
        "Tap the card body.",
        "The sheet rises from the bottom and covers up to ~85% of the "
        "screen. Scroll inside it if the item list is long.",
        "Swipe it back down, or tap the dimmed area above it, to close. "
        "Nothing on this sheet can be edited — change status from the "
        "card instead.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Alerts and notifications", "".join([
    lead("The app tells you about every new or changed order two ways at "
         "once, so nothing is missed."),
    table(["Alert", "When", "Looks like"], [
        ["<b>In-app banner</b>", "A live event arrives while you are looking "
         "at the app", "A short bar slides up from the bottom, e.g. "
         "<i>“New order #1234 · 3 items · PHP 540.00”</i>. "
         "Disappears after a few seconds."],
        ["<b>Phone notification</b>", "Any live event, foreground or "
         "background", "A standard Android notification in the <i>Live "
         "orders</i> channel, with a heads-up pop and sound."],
    ]),
    h3("Notification messages you'll see"),
    table(["Event", "Notification"], [
        ["New order", "<i>New order #‹id›</i> — item count and "
         "total"],
        ["Order updated", "<i>Order #‹id› updated</i> — "
         "“Status: ‹status›”"],
        ["Order cancelled", "<i>Order #‹id› cancelled</i>"],
        ["Order removed", "<i>Order #‹id› removed</i>"],
    ]),
    h3("Turning notifications on"),
    steps([
        "The first time the app runs it asks for permission to post "
        "notifications. Tap <b>Allow</b>.",
        "If you tapped <i>Don't allow</i> by mistake, open Android "
        "<b>Settings › Apps › Cartivo Merchant › "
        "Notifications</b> and switch them back on.",
        "Keep the <b>Live orders</b> channel set to <i>high importance</i> so "
        "alerts pop up and make a sound.",
    ]),
    note("Right after the app connects, it stays quiet for about 4 seconds "
         "while it catches up on the orders placed while it was closed — "
         "otherwise you'd get a burst of notifications for old orders. Only "
         "genuinely new activity alerts you.", "note"),
]))

# ---------------------------------------------------------------------------
add("Merchant Settings", "".join([
    lead("Tap the <b>gear</b> in the toolbar to open <b>Merchant Settings</b>. "
         "This is where you review the device status and change your store "
         "details."),
    h3("What's on the settings screen"),
    ul([
        "<b>Device status card</b> at the top — the current state "
        "(<i>Waiting for approval</i> / <i>Device approved</i> / <i>Device "
        "deactivated</i>), your merchant name, an explanation, and a "
        "<b>Check status</b> button.",
        "<b>Merchant ID</b> field.",
        "<b>Merchant Name</b> field.",
        "<b>Cancel</b> and <b>Save</b> buttons.",
    ]),
    h3("Changing your store name only"),
    steps([
        "Open <b>Settings</b>, edit <b>Merchant Name</b>, tap <b>Save</b>.",
        "A green <b>“Merchant settings saved”</b> banner confirms "
        "it. The name updates in the toolbar and on your storefront records. "
        "Your orders and device approval are untouched.",
    ]),
    h3("Switching to a different Merchant ID"),
    note("Only do this if your provider has genuinely issued you a new "
         "Merchant ID. Changing it is a full reset of the store link on this "
         "device.", "warn"),
    steps([
        "Open <b>Settings</b>, replace the <b>Merchant ID</b> with the new "
        "one, adjust the name if needed, tap <b>Save</b>.",
        "The app wipes this device's saved credentials for the old merchant "
        "and re-enrols the device under the new Merchant ID.",
        "The device goes back to <b>Pending</b> — your administrator "
        "must approve it again under the new merchant before live orders "
        "resume.",
        "The old merchant's orders are no longer shown.",
    ]),
]))

# ---------------------------------------------------------------------------
add("When the connection drops", "".join([
    lead("The app is built to ride out short outages without you doing "
         "anything. Here is exactly what happens and what you can still do."),
    table(["Situation", "What the app does", "What you can do"], [
        ["Brief Wi-Fi blip",
         "Pill shows <b>Reconnecting</b>, retries with growing gaps (1s, 2s, "
         "4s… up to 30s). Reconnects and replays missed orders "
         "automatically.",
         "Nothing. Wait for it."],
        ["Longer outage",
         "Stays on <b>Reconnecting</b>. The list keeps showing the last "
         "known orders.",
         "Read existing orders. You cannot receive new orders or reliably "
         "save status changes — a change may fail with a red message."],
        ["Airplane mode / no data at all",
         "Pill goes to <b>Reconnecting</b> then effectively idle; a refresh "
         "shows the <i>cached data</i> banner.",
         "Read cached orders only. Restore the connection to resume."],
        ["Connection returns",
         "Reconnects within seconds, pill returns to <b>Live</b>, missed "
         "orders stream in (without a notification storm).",
         "Carry on."],
    ]),
    note("Status changes and cancellations are <b>not queued</b> while "
         "offline. If a change fails, it did not happen — redo it once "
         "the pill is back to <b>Live</b>.", "warn"),
]))

# ---------------------------------------------------------------------------
add("Your daily routine", "".join([
    h3("Opening up"),
    steps([
        "Put the device on its stand / charger where staff can see it.",
        "Open <b>Cartivo Merchant</b>.",
        "Confirm the toolbar shows your store name and the pill reads "
        "<b>Live</b> (green). If it doesn't, see Troubleshooting.",
        "Do a quick <b>pull-to-refresh</b> to be sure the list is current.",
    ]),
    h3("During trading"),
    ul([
        "Work new orders from the top of the <b>Pending</b> tab.",
        "Move each order to <b>Preparing</b> when work starts, <b>Ready</b> "
        "when it's done, <b>Fulfilled</b> when the customer has it.",
        "Cancel only with a real reason — it can't be undone and the "
        "customer is told.",
        "Glance at the pill now and then. Green = fine.",
    ]),
    h3("Closing down"),
    steps([
        "Check the <b>Pending</b> and <b>Preparing</b> tabs are empty (or "
        "deal with what's left).",
        "Leave the device charging and connected — there is no "
        "“sign out” and nothing to back up. The app can stay open.",
    ]),
]))

# ---------------------------------------------------------------------------
add("Troubleshooting & FAQ", "".join([
    h3("The pill never leaves “Connecting” or “Reconnecting”"),
    ol([
        "Check the device is actually online — open a web page in the "
        "browser.",
        "Check the device status: if the toolbar shows an amber hourglass, "
        "the device is still <b>Pending</b> — it needs administrator "
        "approval, not a connection fix.",
        "If it shows a red block icon, the device is <b>Deactivated</b> "
        "— contact your administrator.",
        "Pull down to refresh. If that fails too, close the app fully and "
        "re-open it.",
        "Still stuck: hand the Technical Manual to your IT person — the "
        "server address in the app's configuration may be wrong or "
        "unreachable.",
    ]),
    h3("The pill says “Offline” and won't change"),
    p("“Offline” means the app isn't even trying, which points to "
      "setup rather than the network: no merchant registered, the device not "
      "approved, or the device deactivated. Open <b>Settings</b> and read the "
      "device-status card."),
    h3("I registered but no orders ever arrive"),
    ol([
        "Confirm the <b>Merchant ID</b> in <b>Settings</b> exactly matches "
        "what your provider registered — no extra spaces, right case.",
        "Confirm the device shows <b>Live</b> (approved + connected).",
        "Place a test order on your storefront and watch for it.",
        "If it still doesn't appear, your storefront may not be linked to "
        "this Merchant ID on the provider's side — raise it with them.",
    ]),
    h3("A status change failed"),
    p("You'll see a red message at the bottom of the screen and the pill "
      "won't have moved. This is almost always a momentary connection "
      "problem. Wait for the pill to read <b>Live</b>, then try the change "
      "again."),
    h3("I got a burst of notifications for old orders"),
    p("This can happen after a long time closed or a long outage. It's "
      "harmless — the app is re-syncing. The 4-second quiet window "
      "usually suppresses it; a very large backlog can still leak a few."),
    h3("Frequently asked"),
    table(["Question", "Answer"], [
        ["Is there a login or PIN?", "No. Whoever holds the unlocked device "
         "can use it. Lock the device itself."],
        ["Can two devices show the same store?", "Yes. Register each device "
         "with the same Merchant ID and have each one approved. They stay in "
         "sync over the live feed."],
        ["Does it work on iPhone?", "No — Android only."],
        ["Do I need to back anything up?", "No. All order history lives on "
         "the server; the device copy is just a cache."],
        ["Can I print an order?", "Not from this app. It has no printing."],
        ["What currency is the ₱ total in?", "Whatever currency your "
         "storefront sends. The symbol shown is a peso sign regardless."],
    ]),
]))
