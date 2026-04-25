const fs = require('fs');
const path = require('path');

const outDir = path.join(__dirname, 'out');
const categoriesReport = JSON.parse(
  fs.readFileSync(path.join(outDir, 'product-category-pages.json'), 'utf8')
);
const menuEditHtml = fs.readFileSync(path.join(outDir, 'menu-edit.html'), 'utf8');

function decodeHtml(value) {
  return value
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#039;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&#(\d+);/g, (_, code) => String.fromCharCode(Number(code)))
    .replace(/&#x([0-9a-f]+);/gi, (_, code) => String.fromCharCode(parseInt(code, 16)));
}

function extract(input, pattern) {
  const match = input.match(pattern);
  return match ? decodeHtml(match[1].trim()) : '';
}

function parseMenuItems(html) {
  const items = [];
  const itemPattern = /<li id="menu-item-(\d+)" class="menu-item menu-item-depth-(\d+)[\s\S]*?<\/li>/g;
  let match;

  while ((match = itemPattern.exec(html))) {
    const block = match[0];
    const menuItemDbId = Number(match[1]);
    const depth = Number(match[2]);
    const title = extract(block, /<span class="item-title">([\s\S]*?)<\/span>/);
    const objectId = Number(extract(block, /name="menu-item-object-id\[\d+\]" value="([^"]*)"/) || '0');
    const parentMenuItemId = Number(
      extract(block, /name="menu-item-parent-id\[\d+\]" value="([^"]*)"/) || '0'
    );
    const itemType = extract(block, /name="menu-item-type\[\d+\]" value="([^"]*)"/);
    const object = extract(block, /name="menu-item-object\[\d+\]" value="([^"]*)"/);

    items.push({
      menuItemDbId,
      depth,
      title,
      objectId,
      parentMenuItemId,
      itemType,
      object,
    });
  }

  return items;
}

function buildPath(categoryById, id) {
  const parts = [];
  let current = categoryById.get(id);

  while (current) {
    parts.unshift(current.name);
    current = current.parentId ? categoryById.get(current.parentId) : null;
  }

  return parts;
}

const categories = categoriesReport.items;
const menuItems = parseMenuItems(menuEditHtml);
const menuCategoryItems = menuItems.filter(
  (item) => item.itemType === 'taxonomy' && item.object === 'product_cat'
);
const categoryById = new Map(categories.map((category) => [category.id, category]));
const menuByObjectId = new Map(menuCategoryItems.map((item) => [item.objectId, item]));

const missingCategories = categories
  .filter((category) => !menuByObjectId.has(category.id))
  .map((category) => {
    const parentMenuItem =
      category.parentId && menuByObjectId.has(category.parentId)
        ? menuByObjectId.get(category.parentId)
        : null;

    return {
      id: category.id,
      name: category.name,
      level: category.level,
      parentId: category.parentId,
      path: buildPath(categoryById, category.id).join(' > '),
      hasParentInMenu: Boolean(parentMenuItem),
      parentMenuItemDbId: parentMenuItem?.menuItemDbId || 0,
    };
  });

const report = {
  counts: {
    productCategories: categories.length,
    menuProductCategoryItems: menuCategoryItems.length,
    missingCategories: missingCategories.length,
    actionableMissing: missingCategories.filter((category) => category.hasParentInMenu).length,
  },
  missingCategories,
  actionableMissing: missingCategories.filter((category) => category.hasParentInMenu),
};

fs.writeFileSync(path.join(outDir, 'full-compare-report.json'), JSON.stringify(report, null, 2), 'utf8');
console.log(JSON.stringify(report, null, 2));
