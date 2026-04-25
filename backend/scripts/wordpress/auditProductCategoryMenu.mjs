import {
  buildDuplicateSummary,
  buildHierarchyMismatches,
  fetchAllProductCategories,
  fetchMenuItems,
  gotoMenuEditor,
  groupProductMenuItems,
  launchWordPressBrowser,
  loginToWordPress,
  resolveMenuId,
  resolveSyncConfig,
  selectPrimaryMenuItems,
  writeReport,
} from './productCategoryMenuSync.mjs';

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const categories = await fetchAllProductCategories(page, config);
    const menuId = await resolveMenuId(page, config);
    await gotoMenuEditor(page, config, menuId);

    const menuItems = await fetchMenuItems(page);
    const grouped = groupProductMenuItems(menuItems);
    const primaryByCategoryId = selectPrimaryMenuItems(categories, grouped);
    const mismatches = buildHierarchyMismatches(categories, primaryByCategoryId);
    const duplicates = buildDuplicateSummary(grouped);
    const missing = categories.filter((category) => !grouped.byObjectId.has(category.id));

    const report = {
      menuId,
      counts: {
        categories: categories.length,
        productMenuItems: grouped.productMenuItems.length,
        duplicates: duplicates.length,
        missing: missing.length,
        hierarchyMismatches: mismatches.length,
      },
      missing,
      mismatches,
      duplicates,
    };

    writeReport('audit-product-category-menu.json', report);
    console.log(JSON.stringify(report, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
