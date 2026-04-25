import {
  applyHierarchyUpdates,
  buildDuplicateSummary,
  buildHierarchyMismatches,
  fetchAllProductCategories,
  fetchMenuItems,
  gotoMenuEditor,
  groupProductMenuItems,
  injectMissingCategories,
  launchWordPressBrowser,
  loginToWordPress,
  resolveMenuId,
  resolveSyncConfig,
  saveMenu,
  selectPrimaryMenuItems,
  writeReport,
  indexCategories,
} from './productCategoryMenuSync.mjs';

async function main() {
  const config = resolveSyncConfig();
  const { browser, page } = await launchWordPressBrowser(config);

  try {
    await loginToWordPress(page, config);

    const categories = await fetchAllProductCategories(page, config);
    const categoryById = indexCategories(categories);
    const menuId = await resolveMenuId(page, config);
    await gotoMenuEditor(page, config, menuId);

    let menuItems = await fetchMenuItems(page);
    let grouped = groupProductMenuItems(menuItems);
    let primaryByCategoryId = selectPrimaryMenuItems(categories, grouped);
    const missing = categories.filter((category) => !grouped.byObjectId.has(category.id));

    let addedIds = [];
    if (missing.length) {
      addedIds = await injectMissingCategories(page, missing, categoryById, config);
      menuItems = await fetchMenuItems(page);
      grouped = groupProductMenuItems(menuItems);
      primaryByCategoryId = selectPrimaryMenuItems(categories, grouped);
    }

    let mismatches = buildHierarchyMismatches(categories, primaryByCategoryId);
    let updatedIds = [];

    if (addedIds.length || mismatches.length) {
      if (mismatches.length) {
        updatedIds = await applyHierarchyUpdates(page, mismatches);
      }

      await saveMenu(page);

      menuItems = await fetchMenuItems(page);
      grouped = groupProductMenuItems(menuItems);
      primaryByCategoryId = selectPrimaryMenuItems(categories, grouped);
      mismatches = buildHierarchyMismatches(categories, primaryByCategoryId);
    }

    const duplicates = buildDuplicateSummary(grouped);
    const remainingMissing = categories.filter((category) => !grouped.byObjectId.has(category.id));

    const report = {
      menuId,
      addedIds,
      updatedIds,
      counts: {
        categories: categories.length,
        productMenuItems: grouped.productMenuItems.length,
        duplicates: duplicates.length,
        remainingMissing: remainingMissing.length,
        remainingHierarchyMismatches: mismatches.length,
      },
      remainingMissing,
      remainingHierarchyMismatches: mismatches,
      duplicates,
    };

    writeReport('sync-product-category-menu.json', report);
    console.log(JSON.stringify(report, null, 2));

    if (remainingMissing.length || mismatches.length) {
      throw new Error('Menu sync completed with remaining discrepancies.');
    }
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
