const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
  ShadingType, VerticalAlign, PageNumber, PageBreak, LevelFormat,
  TableOfContents, ExternalHyperlink, Bookmark, InternalHyperlink
} = require("docx");
const fs = require("fs");

const BRAND_TEAL = "1B7A8C";
const BRAND_OLIVE = "BCBE68";
const LIGHT_TEAL = "E8F4F6";
const LIGHT_GRAY = "F5F5F5";
const MID_GRAY = "CCCCCC";
const DARK_TEXT = "1A1A1A";
const WHITE = "FFFFFF";

const PAGE_WIDTH = 12240;
const PAGE_HEIGHT = 15840;
const MARGIN = 1440;
const CONTENT_WIDTH = PAGE_WIDTH - MARGIN * 2; // 9360

function heading1(text, bookmarkId) {
  const children = bookmarkId
    ? [new Bookmark({ id: bookmarkId, children: [new TextRun({ text, bold: true, size: 36, color: WHITE, font: "Arial" })] })]
    : [new TextRun({ text, bold: true, size: 36, color: WHITE, font: "Arial" })];
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    shading: { fill: BRAND_TEAL, type: ShadingType.CLEAR },
    border: { bottom: { style: BorderStyle.SINGLE, size: 3, color: BRAND_OLIVE } },
    spacing: { before: 360, after: 200 },
    indent: { left: 120 },
    children,
  });
}

function heading2(text, bookmarkId) {
  const children = bookmarkId
    ? [new Bookmark({ id: bookmarkId, children: [new TextRun({ text, bold: true, size: 28, color: BRAND_TEAL, font: "Arial" })] })]
    : [new TextRun({ text, bold: true, size: 28, color: BRAND_TEAL, font: "Arial" })];
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    border: { bottom: { style: BorderStyle.SINGLE, size: 2, color: BRAND_OLIVE } },
    spacing: { before: 280, after: 120 },
    children,
  });
}

function heading3(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 200, after: 80 },
    children: [new TextRun({ text, bold: true, size: 24, color: "333333", font: "Arial" })],
  });
}

function body(text, opts = {}) {
  return new Paragraph({
    spacing: { before: 60, after: 100 },
    children: [new TextRun({ text, size: 22, font: "Arial", color: DARK_TEXT, ...opts })],
  });
}

function bulletItem(text, bold = false) {
  return new Paragraph({
    numbering: { reference: "bullets", level: 0 },
    spacing: { before: 40, after: 40 },
    children: [new TextRun({ text, size: 22, font: "Arial", bold, color: DARK_TEXT })],
  });
}

function numberedItem(text) {
  return new Paragraph({
    numbering: { reference: "numbers", level: 0 },
    spacing: { before: 40, after: 40 },
    children: [new TextRun({ text, size: 22, font: "Arial", color: DARK_TEXT })],
  });
}

function noteBox(label, text, color = LIGHT_TEAL, borderColor = BRAND_TEAL) {
  return new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [CONTENT_WIDTH],
    rows: [
      new TableRow({
        children: [
          new TableCell({
            borders: {
              top: { style: BorderStyle.SINGLE, size: 3, color: borderColor },
              bottom: { style: BorderStyle.SINGLE, size: 1, color: MID_GRAY },
              left: { style: BorderStyle.THICK, size: 12, color: borderColor },
              right: { style: BorderStyle.SINGLE, size: 1, color: MID_GRAY },
            },
            shading: { fill: color, type: ShadingType.CLEAR },
            margins: { top: 100, bottom: 100, left: 160, right: 160 },
            width: { size: CONTENT_WIDTH, type: WidthType.DXA },
            children: [
              new Paragraph({
                children: [
                  new TextRun({ text: label + " ", bold: true, size: 20, font: "Arial", color: borderColor }),
                  new TextRun({ text, size: 20, font: "Arial", color: DARK_TEXT }),
                ],
              }),
            ],
          }),
        ],
      }),
    ],
  });
}

function spacer(pts = 120) {
  return new Paragraph({ spacing: { before: pts, after: 0 }, children: [] });
}

function infoTable(rows) {
  const border = { style: BorderStyle.SINGLE, size: 1, color: MID_GRAY };
  const borders = { top: border, bottom: border, left: border, right: border };
  return new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [3000, 6360],
    rows: rows.map(([label, value], i) =>
      new TableRow({
        children: [
          new TableCell({
            borders,
            shading: { fill: i % 2 === 0 ? LIGHT_TEAL : WHITE, type: ShadingType.CLEAR },
            margins: { top: 80, bottom: 80, left: 120, right: 120 },
            width: { size: 3000, type: WidthType.DXA },
            children: [new Paragraph({ children: [new TextRun({ text: label, bold: true, size: 20, font: "Arial", color: BRAND_TEAL })] })],
          }),
          new TableCell({
            borders,
            shading: { fill: i % 2 === 0 ? LIGHT_TEAL : WHITE, type: ShadingType.CLEAR },
            margins: { top: 80, bottom: 80, left: 120, right: 120 },
            width: { size: 6360, type: WidthType.DXA },
            children: [new Paragraph({ children: [new TextRun({ text: value, size: 20, font: "Arial", color: DARK_TEXT })] })],
          }),
        ],
      })
    ),
  });
}

function stepTable(steps) {
  const border = { style: BorderStyle.SINGLE, size: 1, color: MID_GRAY };
  const borders = { top: border, bottom: border, left: border, right: border };
  return new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [900, 8460],
    rows: steps.map(([num, text]) =>
      new TableRow({
        children: [
          new TableCell({
            borders,
            shading: { fill: BRAND_TEAL, type: ShadingType.CLEAR },
            margins: { top: 80, bottom: 80, left: 120, right: 120 },
            width: { size: 900, type: WidthType.DXA },
            verticalAlign: VerticalAlign.CENTER,
            children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: String(num), bold: true, size: 24, font: "Arial", color: WHITE })] })],
          }),
          new TableCell({
            borders,
            shading: { fill: LIGHT_GRAY, type: ShadingType.CLEAR },
            margins: { top: 80, bottom: 80, left: 160, right: 120 },
            width: { size: 8460, type: WidthType.DXA },
            children: [new Paragraph({ children: [new TextRun({ text, size: 21, font: "Arial", color: DARK_TEXT })] })],
          }),
        ],
      })
    ),
  });
}

function coverPage() {
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 2880, after: 0 },
      shading: { fill: BRAND_TEAL, type: ShadingType.CLEAR },
      children: [new TextRun({ text: "POSKiosk", size: 64, bold: true, font: "Arial", color: WHITE })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      shading: { fill: BRAND_TEAL, type: ShadingType.CLEAR },
      spacing: { before: 60, after: 0 },
      children: [new TextRun({ text: "Point of Sale System", size: 36, font: "Arial", color: BRAND_OLIVE })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      shading: { fill: BRAND_TEAL, type: ShadingType.CLEAR },
      spacing: { before: 480, after: 0 },
      children: [new TextRun({ text: "ADMINISTRATOR & SUPERVISOR", size: 48, bold: true, font: "Arial", color: WHITE })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      shading: { fill: BRAND_TEAL, type: ShadingType.CLEAR },
      spacing: { before: 40, after: 0 },
      children: [new TextRun({ text: "USER MANUAL", size: 48, bold: true, font: "Arial", color: WHITE })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      shading: { fill: BRAND_TEAL, type: ShadingType.CLEAR },
      spacing: { before: 480, after: 0 },
      children: [new TextRun({ text: "Version 1.0  |  June 2026", size: 24, font: "Arial", color: "CCEEEE" })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      shading: { fill: BRAND_TEAL, type: ShadingType.CLEAR },
      spacing: { before: 2880, after: 0 },
      border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: BRAND_OLIVE } },
      children: [new TextRun({ text: "CONFIDENTIAL — FOR AUTHORIZED PERSONNEL ONLY", size: 18, font: "Arial", color: "AACCCC", italics: true })],
    }),
    new Paragraph({ children: [new PageBreak()] }),
  ];
}

const doc = new Document({
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }],
      },
      {
        reference: "numbers",
        levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } } }],
      },
    ],
  },
  styles: {
    default: { document: { run: { font: "Arial", size: 22 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 36, bold: true, font: "Arial", color: WHITE },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: "Arial", color: BRAND_TEAL },
        paragraph: { spacing: { before: 280, after: 120 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: "Arial", color: "333333" },
        paragraph: { spacing: { before: 200, after: 80 }, outlineLevel: 2 } },
    ],
  },
  sections: [
    {
      properties: {
        page: {
          size: { width: PAGE_WIDTH, height: PAGE_HEIGHT },
          margin: { top: MARGIN, right: MARGIN, bottom: MARGIN, left: MARGIN },
        },
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              border: { bottom: { style: BorderStyle.SINGLE, size: 3, color: BRAND_TEAL } },
              children: [
                new TextRun({ text: "POSKiosk  ", bold: true, size: 18, font: "Arial", color: BRAND_TEAL }),
                new TextRun({ text: "Admin & Supervisor Manual", size: 18, font: "Arial", color: "666666" }),
              ],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              border: { top: { style: BorderStyle.SINGLE, size: 3, color: BRAND_TEAL } },
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun({ text: "Page ", size: 18, font: "Arial", color: "666666" }),
                new TextRun({ children: [PageNumber.CURRENT], size: 18, font: "Arial", color: "666666" }),
                new TextRun({ text: " of ", size: 18, font: "Arial", color: "666666" }),
                new TextRun({ children: [PageNumber.TOTAL_PAGES], size: 18, font: "Arial", color: "666666" }),
              ],
            }),
          ],
        }),
      },
      children: [
        // Cover page
        ...coverPage(),

        // TOC page
        heading1("Table of Contents"),
        new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-3" }),
        new Paragraph({ children: [new PageBreak()] }),

        // 1. Introduction
        heading1("1. Introduction", "intro"),
        body("This manual is intended for Administrators and Supervisors of the POSKiosk Point of Sale system. It covers all management functions including user administration, catalog setup, sales operations, reporting, and system configuration."),
        spacer(),
        heading2("1.1 About POSKiosk"),
        body("POSKiosk is a Windows-based Point of Sale system consisting of:"),
        bulletItem("A kiosk Flutter application that runs on the sales floor"),
        bulletItem("A NestJS backend service running locally as a Windows service"),
        bulletItem("A PostgreSQL database for data persistence"),
        spacer(),
        heading2("1.2 Role Hierarchy"),
        body("The system has three user roles with different levels of access:"),
        spacer(),
        infoTable([
          ["Admin", "Full system access — user management, catalog, settings, reports, and all sales operations"],
          ["Supervisor", "Elevated sales access — can void orders, process refunds, view reports, and authorize transactions"],
          ["Cashier (User)", "Daily sales operations — create orders, accept payments, apply discounts"],
        ]),
        spacer(),
        noteBox("NOTE:", "Admins have the highest level of access and can perform all Supervisor and Cashier actions in addition to their exclusive admin functions."),
        spacer(),

        // 2. Logging In
        heading1("2. Logging In", "login"),
        body("The POSKiosk system supports three login methods. Admins and Supervisors typically use Email or User ID login."),
        spacer(),
        heading2("2.1 Login Methods"),
        spacer(),
        infoTable([
          ["Email + Password", "Log in using your registered email address and password"],
          ["User ID + Password", "Log in using your assigned numeric User ID and password"],
          ["PIN Login", "Quick PIN entry for kiosk sessions — set up during first login"],
        ]),
        spacer(),
        heading2("2.2 Steps to Log In"),
        spacer(),
        stepTable([
          [1, "Launch the POSKiosk application from the desktop shortcut."],
          [2, "On the Login screen, select your preferred login method (Email, User ID, or PIN)."],
          [3, "Enter your credentials and press the Login button."],
          [4, "On first login, you will be prompted to set up a PIN for faster future access."],
          [5, "After successful login, the main menu will appear based on your assigned role."],
        ]),
        spacer(),
        noteBox("TIP:", "Supervisors may be asked to enter their PIN to authorize void or discount operations even when they are not the currently logged-in user."),
        spacer(),
        new Paragraph({ children: [new PageBreak()] }),

        // 3. User Management (Admin Only)
        heading1("3. User Management (Admin Only)", "users"),
        body("Only Administrators can create, edit, and delete user accounts. Access User Management from the main navigation menu."),
        spacer(),
        heading2("3.1 Viewing Users"),
        body("The User Management screen shows a searchable, filterable table of all system users."),
        bulletItem("Search by name, email, or User ID"),
        bulletItem("Filter by role (Admin, Supervisor, Cashier)"),
        bulletItem("View user status, assigned group, and last login"),
        spacer(),
        heading2("3.2 Creating a New User"),
        spacer(),
        stepTable([
          [1, "Navigate to the main menu and select User Management."],
          [2, "Click the Create User button (usually a \"+\" icon or labeled button)."],
          [3, "Fill in the required fields: Full Name, Email, User ID, Password, and Role."],
          [4, "Optionally assign the user to a User Group for permission management."],
          [5, "Click Save or Confirm to create the account. The user can now log in."],
        ]),
        spacer(),
        heading2("3.3 Editing a User"),
        body("To update a user's information:"),
        numberedItem("Locate the user in the User Management table."),
        numberedItem("Click the Edit icon or select Edit from the action menu."),
        numberedItem("Modify the desired fields (name, email, role, group, etc.)."),
        numberedItem("Click Save to apply changes."),
        spacer(),
        heading2("3.4 Deleting a User"),
        spacer(),
        noteBox("WARNING:", "Deleting a user is permanent. Their historical transaction data will be retained, but they will no longer be able to log in.", "FFF3E0", "E65100"),
        spacer(),
        numberedItem("Find the user in the User Management table."),
        numberedItem("Click the Delete icon or select Delete from the action menu."),
        numberedItem("Confirm the deletion in the confirmation dialog."),
        spacer(),
        heading2("3.5 User Groups & Permissions"),
        body("User Groups control granular feature access within the system. Each group can have different permissions for different menus (e.g., Sales, Reports, Admin)."),
        bulletItem("Assign users to groups that match their job responsibilities"),
        bulletItem("Permissions are arrays of actions per menu (e.g., create, read, update, void, discount)"),
        bulletItem("Contact your system administrator if group permissions need to be adjusted"),
        spacer(),
        new Paragraph({ children: [new PageBreak()] }),

        // 4. Catalog Management (Admin Only)
        heading1("4. Catalog Management (Admin Only)", "catalog"),
        body("The catalog is the complete list of products available for sale. Admins manage product groups, individual products, variants, and modifiers."),
        spacer(),
        heading2("4.1 Product Groups"),
        body("Product Groups are categories that organize products (e.g., Beverages, Food, Snacks)."),
        spacer(),
        heading3("Creating a Product Group"),
        stepTable([
          [1, "Navigate to Catalog in the main menu."],
          [2, "Select Product Groups."],
          [3, "Click Create / Add Group."],
          [4, "Enter the group name and optionally upload a cover image."],
          [5, "Click Save to create the group."],
        ]),
        spacer(),
        heading3("Editing / Deleting a Product Group"),
        bulletItem("Select the group from the list and click Edit to update its name or image."),
        bulletItem("Click Delete to remove the group. Note: groups with products cannot be deleted until products are moved or removed."),
        spacer(),
        heading2("4.2 Products"),
        body("Products are individual items for sale. Each product belongs to a product group."),
        spacer(),
        heading3("Creating a Product"),
        stepTable([
          [1, "Navigate to Catalog > Products."],
          [2, "Click Create / Add Product."],
          [3, "Fill in: Product Name, Description, Price, and select a Product Group."],
          [4, "Upload a product image (optional but recommended)."],
          [5, "Set availability (toggle Is Available on/off)."],
          [6, "Assign a Sort Order to control display order in the kiosk."],
          [7, "Link Modifier Groups if the product has customizable options."],
          [8, "Click Save to publish the product."],
        ]),
        spacer(),
        heading3("Managing Product Availability"),
        bulletItem("Toggle Is Available to temporarily hide a product from the kiosk without deleting it."),
        bulletItem("Use Sort Order to control the display sequence within a group."),
        spacer(),
        heading2("4.3 Product Variants"),
        body("Variants represent size or option variations of a product (e.g., Small, Medium, Large)."),
        bulletItem("Navigate to Catalog > Products > select a product > Variants."),
        bulletItem("Create variants with their own name, price, and availability."),
        bulletItem("Each variant can have different modifiers assigned."),
        spacer(),
        heading2("4.4 Modifier Groups"),
        body("Modifier Groups are add-on or customization options (e.g., Extra Shot, Sugar Level, Toppings)."),
        spacer(),
        stepTable([
          [1, "Navigate to Catalog > Modifier Groups."],
          [2, "Click Create Modifier Group."],
          [3, "Enter the group name and set whether selection is required."],
          [4, "Add individual modifier options with their names and additional prices."],
          [5, "Assign the modifier group to the relevant products."],
          [6, "Click Save."],
        ]),
        spacer(),
        new Paragraph({ children: [new PageBreak()] }),

        // 5. Discounts (Admin)
        heading1("5. Discount Management (Admin Only)", "discounts"),
        body("Admins can create and manage the discount schemes available at checkout."),
        spacer(),
        heading2("5.1 Discount Types"),
        spacer(),
        infoTable([
          ["Senior / PWD Discount", "Government-mandated discount requiring a beneficiary ID number at checkout"],
          ["Promo Discount", "Custom percentage or fixed-amount discounts for promotions"],
          ["Item-Level Discount", "Applied to individual line items in an order"],
          ["Order-Level Discount", "Applied to the entire order total"],
        ]),
        spacer(),
        heading2("5.2 Creating a Discount"),
        stepTable([
          [1, "Navigate to the Discounts section from the main menu."],
          [2, "Click Create Discount."],
          [3, "Enter the discount name, type (percentage or fixed), and value."],
          [4, "Set eligibility rules (e.g., requires beneficiary ID for Senior/PWD)."],
          [5, "Set active/inactive status."],
          [6, "Click Save."],
        ]),
        spacer(),
        noteBox("NOTE:", "Cashiers can apply active discounts at checkout, but cannot create or modify discount schemes."),
        spacer(),
        new Paragraph({ children: [new PageBreak()] }),

        // 6. Sales Operations
        heading1("6. Sales Operations", "sales"),
        body("Administrators and Supervisors can perform all standard sales operations in addition to elevated actions like voiding orders and processing refunds."),
        spacer(),
        heading2("6.1 Creating a Sales Order"),
        stepTable([
          [1, "From the main menu, select Sales / Ordering."],
          [2, "Browse products by category or use the search function."],
          [3, "Tap a product to add it to the cart. Tap multiple times to increase quantity."],
          [4, "If a product has modifiers (e.g., size, add-ons), a selection dialog will appear."],
          [5, "Review the cart panel on the right side of the screen."],
          [6, "Tap Checkout or Proceed to Payment when ready."],
        ]),
        spacer(),
        heading2("6.2 Applying Discounts"),
        stepTable([
          [1, "On the cart or checkout screen, tap Apply Discount."],
          [2, "Select the discount type (Senior/PWD, Promo, etc.)."],
          [3, "If required, enter the beneficiary ID number."],
          [4, "Select which items the discount applies to (or apply to the whole order)."],
          [5, "Confirm to apply. The discount will be reflected in the order total."],
        ]),
        spacer(),
        heading2("6.3 Processing Payment"),
        stepTable([
          [1, "On the Payment screen, select the payment method (Cash, Card, E-wallet)."],
          [2, "For cash payments, enter the amount tendered. The system calculates change automatically."],
          [3, "Confirm the payment to complete the transaction."],
          [4, "The receipt screen will appear. Print the receipt if required."],
        ]),
        spacer(),
        heading2("6.4 Voiding a Sales Order (Supervisor / Admin)"),
        body("Voiding cancels a completed or pending order. This action requires Supervisor or Admin PIN authorization."),
        spacer(),
        noteBox("WARNING:", "Voided orders cannot be un-voided. Ensure the reason for voiding is correct before proceeding.", "FFF3E0", "E65100"),
        spacer(),
        stepTable([
          [1, "Navigate to Transactions from the main menu."],
          [2, "Locate the order to void using date filters or the search bar."],
          [3, "Select the order and tap Void Order."],
          [4, "A PIN authorization dialog will appear. A Supervisor or Admin must enter their PIN to proceed."],
          [5, "Confirm the void. The order status will be updated to Voided."],
        ]),
        spacer(),
        heading2("6.5 Processing a Refund (Supervisor / Admin)"),
        stepTable([
          [1, "Navigate to Transactions and find the completed order."],
          [2, "Select the order and tap Process Refund."],
          [3, "Select the items to refund (partial or full refund)."],
          [4, "Choose the refund method (same as original payment or alternative)."],
          [5, "Confirm to process. The refund record is created and the order is updated."],
        ]),
        spacer(),
        new Paragraph({ children: [new PageBreak()] }),

        // 7. Reports
        heading1("7. Reports & Analytics", "reports"),
        body("Both Admins and Supervisors can access the Reports section to view and export sales performance data."),
        spacer(),
        heading2("7.1 Available Report Types"),
        spacer(),
        infoTable([
          ["Total Sales Summary", "Overall revenue, transaction count, and averages for a date range"],
          ["Hourly Breakdown", "Sales volume by hour of day — useful for staffing decisions"],
          ["Daily Breakdown", "Day-by-day sales totals across a date range"],
          ["Monthly Breakdown", "Month-over-month performance comparison"],
          ["By Product Group", "Revenue breakdown by category (Beverages, Food, etc.)"],
          ["By Product", "Top-selling items and revenue per product"],
          ["By Cashier (User)", "Sales performance per staff member"],
          ["By Payment Method", "Cash vs card vs e-wallet split"],
        ]),
        spacer(),
        heading2("7.2 Generating a Report"),
        stepTable([
          [1, "Navigate to Reports from the main menu."],
          [2, "Select the report type from the list or tabs."],
          [3, "Set the date range using the date pickers (From / To)."],
          [4, "The report data will load automatically. Scroll to view all results."],
          [5, "To export, tap the Export button and select the output format."],
        ]),
        spacer(),
        heading2("7.3 Exportable Report (Admin Only)"),
        body("The Exportable Report shows transactions that have not yet been exported to an external system."),
        bulletItem("Navigate to Reports > Exportable Report."),
        bulletItem("Review the list of unexported transactions."),
        bulletItem("Tap Mark as Exported to flag them after external processing."),
        noteBox("NOTE:", "Only Admins can mark transactions as exported. This is typically used for accounting integrations."),
        spacer(),
        new Paragraph({ children: [new PageBreak()] }),

        // 8. Store Configuration (Admin Only)
        heading1("8. Store Configuration (Admin Only)", "settings"),
        body("Administrators can configure store-level settings including the POS terminal, payment methods, and store information."),
        spacer(),
        heading2("8.1 POS Terminal Setup"),
        body("Each kiosk device must be registered as a POS Terminal."),
        stepTable([
          [1, "Navigate to Settings > POS Terminal."],
          [2, "View or edit the terminal's name, assigned store, and details."],
          [3, "To register a new terminal, use the Register Terminal function."],
        ]),
        spacer(),
        heading2("8.2 Payment Methods"),
        body("Configure the payment methods accepted at this terminal (Cash, Card, E-wallet, etc.)."),
        numberedItem("Navigate to Settings > POS Terminal > Payment Methods."),
        numberedItem("Click Add Payment Method and enter the name and type."),
        numberedItem("Toggle methods active/inactive as needed."),
        numberedItem("Click Save. Changes take effect immediately."),
        spacer(),
        heading2("8.3 Franchisee / Store Information"),
        body("Update store name, address, contact, and receipt branding details."),
        bulletItem("Navigate to Settings > Franchisee Info."),
        bulletItem("Edit the store name, address, phone number, and other details."),
        bulletItem("These details appear on printed receipts."),
        spacer(),
        heading2("8.4 Tax Categories"),
        body("Admins can create and manage tax categories applied to products."),
        bulletItem("Navigate to Settings > Tax Categories."),
        bulletItem("Create categories with the applicable tax rate (percentage)."),
        bulletItem("Assign tax categories to products in the catalog."),
        spacer(),
        heading2("8.5 Currencies"),
        body("Configure the base currency for the store."),
        bulletItem("Navigate to Settings > Currencies."),
        bulletItem("Add or update currency definitions including symbol and code."),
        spacer(),
        new Paragraph({ children: [new PageBreak()] }),

        // 9. Inventory (Admin)
        heading1("9. Inventory Management (Admin Only)", "inventory"),
        body("The inventory system tracks materials (raw ingredients or supplies) and recipes (how products consume materials)."),
        spacer(),
        heading2("9.1 Materials"),
        body("Materials represent consumable items (e.g., coffee beans, cups, syrup)."),
        bulletItem("Navigate to Inventory > Materials."),
        bulletItem("Create materials with name, unit of measure (UOM), and material type."),
        bulletItem("Track current stock levels via Inventory Stocks."),
        spacer(),
        heading2("9.2 Recipes"),
        body("Recipes define how much of each material is consumed when a product is sold."),
        stepTable([
          [1, "Navigate to Inventory > Recipes."],
          [2, "Click Create Recipe and select the product it applies to."],
          [3, "Add material components with their quantities and UOM."],
          [4, "Save the recipe. Stock will be deducted automatically when sales are made."],
        ]),
        spacer(),
        heading2("9.3 Inventory Counts"),
        body("Periodically record actual physical counts to reconcile with the system."),
        bulletItem("Navigate to Inventory > Counts and create a new count session."),
        bulletItem("Enter actual quantities for each material."),
        bulletItem("Save to update stock levels based on the physical count."),
        spacer(),
        new Paragraph({ children: [new PageBreak()] }),

        // 10. Troubleshooting
        heading1("10. Troubleshooting", "trouble"),
        spacer(),
        heading2("10.1 Common Issues"),
        spacer(),
        infoTable([
          ["Cannot log in", "Verify your email/User ID and password. Contact Admin to reset your password if locked out."],
          ["Products not showing on kiosk", "Check that products are marked Is Available = true in Catalog > Products."],
          ["Void option not available", "Only Supervisors and Admins can void orders. Ensure you have the correct role."],
          ["Receipt not printing", "Check that the printer is connected and powered on. Verify printer settings in POS Terminal configuration."],
          ["Reports showing no data", "Ensure the selected date range contains completed transactions. Confirm the terminal is correctly registered."],
          ["Backend service not responding", "Restart the POSBackendService via Windows Services or contact your IT administrator."],
        ]),
        spacer(),
        heading2("10.2 System Health"),
        body("The backend provides health check endpoints to verify system status:"),
        bulletItem("Liveness: checks that the backend is running (memory health)"),
        bulletItem("Readiness: confirms the database is accessible (PostgreSQL health)"),
        body("If the system is unresponsive, ask your IT administrator to check the Windows services: POSBackendService and POSPostgres."),
        spacer(),
        new Paragraph({ children: [new PageBreak()] }),

        // 11. Quick Reference
        heading1("11. Quick Reference", "quickref"),
        spacer(),
        heading2("Admin-Only Features"),
        bulletItem("Create, edit, delete users and assign roles"),
        bulletItem("Manage product groups, products, variants, and modifiers"),
        bulletItem("Create and manage discounts"),
        bulletItem("Configure POS terminals and payment methods"),
        bulletItem("Manage store/franchisee information"),
        bulletItem("Manage tax categories and currencies"),
        bulletItem("Access and export all reports including Exportable Report"),
        bulletItem("Manage recipes and inventory materials"),
        spacer(),
        heading2("Supervisor Features"),
        bulletItem("All cashier operations (orders, payments)"),
        bulletItem("Void sales orders (with PIN)"),
        bulletItem("Process refunds"),
        bulletItem("View and export reports"),
        bulletItem("Authorize discounts requiring supervisor approval"),
        spacer(),
        heading2("Shared (Admin + Supervisor)"),
        bulletItem("Create and process sales orders"),
        bulletItem("Apply discounts at checkout"),
        bulletItem("View transaction history"),
        bulletItem("Update own user profile"),
        spacer(),

        // Footer note
        new Paragraph({
          alignment: AlignmentType.CENTER,
          spacing: { before: 480 },
          border: { top: { style: BorderStyle.SINGLE, size: 3, color: BRAND_TEAL } },
          children: [new TextRun({ text: "POSKiosk Admin & Supervisor Manual  |  v1.0  |  June 2026  |  CONFIDENTIAL", size: 18, font: "Arial", color: "888888", italics: true })],
        }),
      ],
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync("C:\\Users\\Jufiel\\Documents\\POS\\docs\\manuals\\POSKiosk-Admin-Supervisor-Manual.docx", buffer);
  console.log("Admin manual created.");
});
