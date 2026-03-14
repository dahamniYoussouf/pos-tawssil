'use client';

import React, { useCallback, useMemo, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import apiClient from '@/lib/api/auth';
import { getLocaleLabel } from '@/lib/locale';
import { ArrowLeft, CirclePlus, Edit, Eye, EyeOff, Layers, Plus, Printer, RefreshCw, RotateCcw, Save, Trash2, X, Zap } from 'lucide-react';

type Promotion = {
  id: string;
  title: string;
  badge_text?: string | null;
};

type PromotionMenuItem = {
  id: string;
  nom?: string | null;
};

type PromotionOption = {
  id: string;
  title?: string | null;
  badge_text?: string | null;
  scope?: string | null;
  type?: string | null;
  is_active?: boolean;
  menu_item_id?: string | null;
  menu_items?: PromotionMenuItem[];
};

type MenuItem = {
  id: string;
  category_id?: string;
  nom: string;
  description?: string | null;
  prix: number;
  display_price?: number;
  photo_url?: string | null;
  temps_preparation?: number | null;
  is_available: boolean;
  additions?: Addition[];
  option_groups?: OptionGroup[];
  promotions?: Promotion[];
};

type Addition = {
  id: string;
  nom: string;
  description?: string | null;
  prix: number;
  is_available: boolean;
  option_group_id?: string | null;
};

type AdditionForm = {
  nom: string;
  description: string;
  prix: string;
  is_available: boolean;
  option_group_id: string;
};

type AdditionModalMode = "create" | "edit";

type OptionGroup = {
  id: string;
  nom: string;
  description?: string | null;
  is_required: boolean;
  ordre_affichage?: number | null;
  additions?: Addition[];
  options?: Addition[];
  options_count?: number;
};

type OptionGroupForm = {
  nom: string;
  description: string;
  is_required: boolean;
  ordre_affichage: string;
};

type OptionGroupModalMode = "create" | "edit";

type FoodCategory = {
  id: string;
  nom: string;
  description?: string | null;
  icone_url?: string | null;
  ordre_affichage?: number | null;
  items?: MenuItem[];
  items_count?: number;
};

type RestaurantInfo = {
  id: string;
  name: string;
  address?: string | null;
  phone_number?: string | null;
  email?: string | null;
  categories?: string[];
  home_categories?: Array<{ id: string; name: string; slug: string }>;
  locale?: string | null;
};

type RestaurantMenuPayload = {
  restaurant_id: string;
  restaurant: RestaurantInfo;
  categories: FoodCategory[];
  total_categories: number;
  total_items: number;
};

type ApiErrorLike = {
  response?: {
    data?: unknown;
  };
  message?: unknown;
};

type ModalType =
  | ''
  | 'create-category'
  | 'edit-category'
  | 'delete-category'
  | 'create-item'
  | 'edit-item'
  | 'delete-item';

type CategoryForm = {
  nom: string;
  description: string;
  icone_url: string;
  ordre_affichage: string;
};

type MenuItemForm = {
  category_id: string;
  nom: string;
  description: string;
  prix: string;
  photo_url: string;
  temps_preparation: string;
  is_available: boolean;
};

type PromotionCreateForm = {
  title: string;
  type: 'percentage' | 'amount' | 'free_delivery' | 'other';
  discount_value: string;
  custom_message: string;
  badge_text: string;
  currency: string;
  start_date: string;
  end_date: string;
  is_active: boolean;
};

type RestaurantPrinter = {
  id: string;
  restaurant_id: string;
  name: string;
  type: 'general' | 'caisse' | 'cuisine' | 'bar';
  ip: string;
  port: number;
  is_enabled: boolean;
  paper_width_mm: 58 | 80;
  created_at?: string;
  updated_at?: string;
};

type PrinterForm = {
  name: string;
  type: 'general' | 'caisse' | 'cuisine';
  connectionType: 'network' | 'local' | 'windows';
  ip: string;
  port: string;
  localPort: string;
  windowsPrinterName: string;
  is_enabled: boolean;
  paper_width_mm: string;
};

function isLocalPrinterIp(ip: string) {
  return /^LPT\d+$/i.test(ip || '') || /^COM\d+$/i.test(ip || '') || /^USB\d+$/i.test(ip || '');
}

function isWindowsPrinterIp(ip: string) {
  return /^WIN:/i.test(ip || '');
}

function getWindowsPrinterDisplayName(ip: string) {
  if (!/^WIN:/i.test(ip || '')) return ip || '';
  return (ip || '').replace(/^WIN:/i, '').trim() || ip || '';
}

const printerTypeLabels: Record<string, string> = {
  general: 'General',
  caisse: 'Caisse',
  cuisine: 'Cuisine',
  bar: 'Bar'
};

const printerTypeBadges: Record<string, string> = {
  general: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-200',
  caisse: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-200',
  cuisine: 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-200',
  bar: 'bg-purple-100 text-purple-800 dark:bg-purple-900/30 dark:text-purple-200'
};

const getPrinterTypeLabel = (type: string) => printerTypeLabels[type] || type;

const getPrinterTypeBadge = (type: string) =>
  printerTypeBadges[type] || printerTypeBadges.general;

const parseNumber = (value: string) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
};

const formatDA = (value: number) => `${new Intl.NumberFormat('fr-FR').format(value)} DA`;

const resolveGroupOptions = (item: MenuItem, group: OptionGroup) => {
  const direct = (group.additions && group.additions.length ? group.additions : group.options) || [];
  const itemAdditions = item.additions || [];
  if (itemAdditions.length === 0) {
    return direct;
  }
  if (direct.length === 0) {
    return itemAdditions.filter((addition) => addition.option_group_id === group.id);
  }
  const merged = [...direct];
  const ids = new Set(direct.map((option) => option.id));
  itemAdditions.forEach((addition) => {
    if (addition.option_group_id === group.id && !ids.has(addition.id)) {
      merged.push(addition);
      ids.add(addition.id);
    }
  });
  return merged;
};

// Fonction pour compter toutes les additions, y compris celles dans les groupes
// Les additions et options sont le meme concept - ce sont toutes des "additions"
// Les additions sans groupe sont maintenant dans un groupe "Additions"
const getAllAdditions = (item: MenuItem): Addition[] => {
  const allAdditions: Addition[] = [];
  const additionIds = new Set<string>();
  
  // Recuperer toutes les options des groupes (qui sont toutes des additions)
  if (item.option_groups) {
    item.option_groups.forEach((group) => {
      const groupOptions = resolveGroupOptions(item, group);
      groupOptions.forEach((option) => {
        if (!additionIds.has(option.id)) {
          allAdditions.push(option);
          additionIds.add(option.id);
        }
      });
    });
  }
  
  // Ajouter les additions qui ne sont dans aucun groupe (pour compatibilite)
  // Normalement elles devraient toutes etre dans le groupe "Additions" maintenant
  const standaloneAdditions = item.additions || [];
  standaloneAdditions.forEach((addition) => {
    if (!additionIds.has(addition.id)) {
      allAdditions.push(addition);
      additionIds.add(addition.id);
    }
  });
  
  return allAdditions;
};

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

const getPromotionLabel = (promotion: {
  id: string;
  title?: string | null;
  badge_text?: string | null;
}) => {
  const title = typeof promotion.title === 'string' ? promotion.title.trim() : '';
  if (title) return title;
  const badge = typeof promotion.badge_text === 'string' ? promotion.badge_text.trim() : '';
  if (badge) return badge;
  return `Promotion ${promotion.id}`;
};

const getPromotionMenuItemIds = (promotion: PromotionOption) => {
  const ids = new Set<string>();
  if (promotion.menu_item_id) {
    ids.add(String(promotion.menu_item_id));
  }
  if (Array.isArray(promotion.menu_items)) {
    promotion.menu_items.forEach((item) => {
      if (item?.id) ids.add(String(item.id));
    });
  }
  return Array.from(ids);
};

const normalizePromotionScope = (scope?: string | null) => String(scope || '').trim().toLowerCase();

const isMenuItemScopedPromotion = (promotion: PromotionOption) => {
  const scope = normalizePromotionScope(promotion.scope);
  const hasMenuItems = Array.isArray(promotion.menu_items) && promotion.menu_items.length > 0;
  if (scope === 'menu_item') return true;
  if (!scope && (hasMenuItems || promotion.menu_item_id)) return true;
  return false;
};

const isPromotionLinkedToItem = (promotion: PromotionOption, menuItemId: string) => {
  if (promotion.menu_item_id && String(promotion.menu_item_id) === menuItemId) {
    return true;
  }
  if (Array.isArray(promotion.menu_items)) {
    return promotion.menu_items.some((item) => String(item.id) === menuItemId);
  }
  return false;
};

const findLinkedPromotion = (promotions: PromotionOption[], menuItemId: string) => {
  const direct = promotions.find(
    (promotion) => promotion.menu_item_id && String(promotion.menu_item_id) === menuItemId
  );
  if (direct) return direct;
  return promotions.find((promotion) => isPromotionLinkedToItem(promotion, menuItemId)) || null;
};

const defaultPromotionCreateForm: PromotionCreateForm = {
  title: '',
  type: 'percentage',
  discount_value: '',
  custom_message: '',
  badge_text: '',
  currency: 'DZD',
  start_date: '',
  end_date: '',
  is_active: true
};

const getApiErrorMessage = (err: unknown, fallback: string) => {
  if (!err || typeof err !== 'object') return fallback;
  const maybe = err as ApiErrorLike;

  const data = maybe.response?.data;
  if (data && typeof data === 'object' && 'message' in data) {
    const message = (data as { message?: unknown }).message;
    if (typeof message === 'string' && message.trim()) return message;
  }

  if (typeof maybe.message === 'string' && maybe.message.trim()) return maybe.message;
  return fallback;
};

const getAuthToken = () => {
  if (typeof window === 'undefined') return '';
  return localStorage.getItem('access_token') || '';
};

const uploadImageFile = async (file: File) => {
  const formData = new FormData();
  formData.append('file', file);

  const token = getAuthToken();
  const response = await fetch(`${API_URL}/api/upload`, {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : undefined,
    body: formData
  });

  if (!response.ok) {
    throw new Error("Echec de l'upload de l'image.");
  }

  const data = await response.json();
  if (!data?.url) {
    throw new Error("URL de l'image manquante.");
  }
  return data.url as string;
};

export default function RestaurantDetailsPage() {
  const router = useRouter();
  const params = useParams();
  const restaurantId = String(params.id || '');

  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [modalError, setModalError] = useState('');
  const [menu, setMenu] = useState<RestaurantMenuPayload | null>(null);
  const [modal, setModal] = useState<ModalType>('');
  const [selectedCategory, setSelectedCategory] = useState<FoodCategory | null>(null);
  const [selectedItem, setSelectedItem] = useState<MenuItem | null>(null);

  const [categoryForm, setCategoryForm] = useState<CategoryForm>({
    nom: '',
    description: '',
    icone_url: '',
    ordre_affichage: ''
  });

  const [itemForm, setItemForm] = useState<MenuItemForm>({
    category_id: '',
    nom: '',
    description: '',
    prix: '',
    photo_url: '',
    temps_preparation: '',
    is_available: true
  });

  const [categoryImageUploading, setCategoryImageUploading] = useState(false);
  const [categoryImagePreview, setCategoryImagePreview] = useState<string | null>(null);
  const [categoryImageError, setCategoryImageError] = useState('');
  const [itemImageUploading, setItemImageUploading] = useState(false);
  const [itemImagePreview, setItemImagePreview] = useState<string | null>(null);
  const [itemImageError, setItemImageError] = useState('');

  const [additionModalOpen, setAdditionModalOpen] = useState(false);
  const [additionModalMode, setAdditionModalMode] = useState<AdditionModalMode>('create');
  const [additionModalItem, setAdditionModalItem] = useState<MenuItem | null>(null);
  const [additionModalAddition, setAdditionModalAddition] = useState<Addition | null>(null);
  const [additionForm, setAdditionForm] = useState<AdditionForm>({
    nom: '',
    description: '',
    prix: '',
    is_available: true,
    option_group_id: ''
  });
  const [additionFormErrors, setAdditionFormErrors] = useState<Record<string, string>>({});
  const [additionModalError, setAdditionModalError] = useState('');
  const [additionSaving, setAdditionSaving] = useState(false);

  const [optionGroupModalOpen, setOptionGroupModalOpen] = useState(false);
  const [optionGroupModalMode, setOptionGroupModalMode] = useState<OptionGroupModalMode>('create');
  const [optionGroupModalItem, setOptionGroupModalItem] = useState<MenuItem | null>(null);
  const [optionGroupModalGroup, setOptionGroupModalGroup] = useState<OptionGroup | null>(null);
  const [optionGroupForm, setOptionGroupForm] = useState<OptionGroupForm>({
    nom: '',
    description: '',
    is_required: false,
    ordre_affichage: ''
  });
  const [optionGroupFormErrors, setOptionGroupFormErrors] = useState<Record<string, string>>({});
  const [optionGroupModalError, setOptionGroupModalError] = useState('');
  const [optionGroupSaving, setOptionGroupSaving] = useState(false);

  const [promotionOptions, setPromotionOptions] = useState<PromotionOption[]>([]);
  const [promotionLoading, setPromotionLoading] = useState(false);
  const [promotionError, setPromotionError] = useState('');
  const [promotionModalOpen, setPromotionModalOpen] = useState(false);
  const [promotionModalItem, setPromotionModalItem] = useState<MenuItem | null>(null);
  const [promotionSelection, setPromotionSelection] = useState('');
  const [promotionModalError, setPromotionModalError] = useState('');
  const [promotionSaving, setPromotionSaving] = useState(false);
  const [promotionCreateOpen, setPromotionCreateOpen] = useState(false);
  const [promotionCreateForm, setPromotionCreateForm] =
    useState<PromotionCreateForm>(defaultPromotionCreateForm);
  const [promotionCreateErrors, setPromotionCreateErrors] = useState<Record<string, string>>({});
  const [promotionCreateError, setPromotionCreateError] = useState('');
  const [promotionCreateSaving, setPromotionCreateSaving] = useState(false);

  const [printers, setPrinters] = useState<RestaurantPrinter[]>([]);
  const [printersLoading, setPrintersLoading] = useState(false);
  const [printerModalOpen, setPrinterModalOpen] = useState(false);
  const [printerModalMode, setPrinterModalMode] = useState<'create' | 'edit'>('create');
  const [printerModalEdit, setPrinterModalEdit] = useState<RestaurantPrinter | null>(null);
  const [printerForm, setPrinterForm] = useState<PrinterForm>({
    name: '',
    type: 'general',
    connectionType: 'network',
    ip: '',
    port: '9100',
    localPort: 'LPT1',
    windowsPrinterName: '',
    is_enabled: true,
    paper_width_mm: '80'
  });
  const [printerFormErrors, setPrinterFormErrors] = useState<Record<string, string>>({});
  const [printerSaving, setPrinterSaving] = useState(false);
  const [printerError, setPrinterError] = useState('');
  const [printerTestingId, setPrinterTestingId] = useState<string | null>(null);

  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const showNotification = useCallback(
    (message: string, type: 'success' | 'error' = 'success') => {
      setToast({ message, type });
      window.setTimeout(() => setToast(null), 3000);
    },
    []
  );

  const [menuQuery, setMenuQuery] = useState('');
  const [availabilityFilter, setAvailabilityFilter] = useState<'all' | 'available' | 'unavailable'>('all');

  const loadMenu = useCallback(async () => {
    if (!restaurantId) return;
    setLoading(true);
    setError('');
    try {
      const response = await apiClient.get(`/restaurant/admin/details/${restaurantId}`, {
        params: { nocache: 'true' }
      });
      setMenu(response.data?.data as RestaurantMenuPayload);
    } catch (err: unknown) {
      setError(getApiErrorMessage(err, 'Erreur lors du chargement du menu'));
    } finally {
      setLoading(false);
    }
  }, [restaurantId]);

  // Fonctions de mise a jour locale pour eviter le rechargement complet
  const updateMenuLocal = useCallback((updater: (menu: RestaurantMenuPayload) => RestaurantMenuPayload) => {
    setMenu((currentMenu) => {
      if (!currentMenu) return currentMenu;
      return updater(currentMenu);
    });
  }, []);

  const updateMenuItemLocal = useCallback((itemId: string, updater: (item: MenuItem) => MenuItem) => {
    updateMenuLocal((menu) => {
      const updatedCategories = menu.categories.map((category) => {
        const updatedItems = (category.items || []).map((item) => {
          if (item.id === itemId) {
            return updater(item);
          }
          return item;
        });
        return { ...category, items: updatedItems };
      });
      return { ...menu, categories: updatedCategories };
    });
  }, [updateMenuLocal]);

  const addMenuItemLocal = useCallback((categoryId: string, newItem: MenuItem) => {
    updateMenuLocal((menu) => {
      const updatedCategories = menu.categories.map((category) => {
        if (category.id === categoryId) {
          return {
            ...category,
            items: [...(category.items || []), newItem]
          };
        }
        return category;
      });
      return { ...menu, categories: updatedCategories };
    });
  }, [updateMenuLocal]);

  const removeMenuItemLocal = useCallback((itemId: string) => {
    updateMenuLocal((menu) => {
      const updatedCategories = menu.categories.map((category) => {
        return {
          ...category,
          items: (category.items || []).filter((item) => item.id !== itemId)
        };
      });
      return { ...menu, categories: updatedCategories };
    });
  }, [updateMenuLocal]);

  const updateOptionGroupLocal = useCallback((itemId: string, groupId: string, updater: (group: OptionGroup) => OptionGroup) => {
    updateMenuItemLocal(itemId, (item) => {
      const updatedGroups = (item.option_groups || []).map((group) => {
        if (group.id === groupId) {
          return updater(group);
        }
        return group;
      });
      return { ...item, option_groups: updatedGroups };
    });
  }, [updateMenuItemLocal]);

  const addOptionGroupLocal = useCallback((itemId: string, newGroup: OptionGroup) => {
    updateMenuItemLocal(itemId, (item) => {
      return {
        ...item,
        option_groups: [...(item.option_groups || []), newGroup]
      };
    });
  }, [updateMenuItemLocal]);

  const removeOptionGroupLocal = useCallback((itemId: string, groupId: string) => {
    updateMenuItemLocal(itemId, (item) => {
      return {
        ...item,
        option_groups: (item.option_groups || []).filter((group) => group.id !== groupId)
      };
    });
  }, [updateMenuItemLocal]);

  const updateAdditionLocal = useCallback((itemId: string, additionId: string, updater: (addition: Addition) => Addition) => {
    updateMenuItemLocal(itemId, (item) => {
      // Trouver l'addition originale pour detecter le changement de groupe
      const originalAddition = (item.additions || []).find((a) => a.id === additionId);
      const updatedAddition = originalAddition ? updater(originalAddition) : updater({} as Addition);
      
      // Mettre a jour dans item.additions
      const updatedAdditions = (item.additions || []).map((addition) => {
        if (addition.id === additionId) {
          return updatedAddition;
        }
        return addition;
      });

      // Si l'addition n'existait pas dans additions, l'ajouter
      if (!originalAddition && updatedAddition.id) {
        updatedAdditions.push(updatedAddition);
      }

      // Detecter le changement de groupe
      const oldGroupId = originalAddition?.option_group_id;
      const newGroupId = updatedAddition.option_group_id;

      // Mettre a jour dans les groupes d'options
      const updatedGroups = (item.option_groups || []).map((group) => {
        const groupOptions = resolveGroupOptions(item, group);
        const hasAddition = groupOptions.some((opt) => opt.id === additionId);
        
        if (hasAddition) {
          // Si l'addition change de groupe, la retirer de l'ancien groupe
          if (oldGroupId && oldGroupId !== newGroupId && group.id === oldGroupId) {
            const updatedOptions = groupOptions.filter((opt) => opt.id !== additionId);
            return {
              ...group,
              options: updatedOptions,
              additions: updatedOptions,
              options_count: updatedOptions.length
            };
          }
          // Si l'addition reste dans le meme groupe, la mettre a jour
          if (group.id === (newGroupId || oldGroupId)) {
            const updatedOptions = groupOptions.map((opt) => {
              if (opt.id === additionId) {
                return updatedAddition;
              }
              return opt;
            });
            return {
              ...group,
              options: updatedOptions,
              additions: updatedOptions,
              options_count: updatedOptions.length
            };
          }
        } else if (newGroupId && group.id === newGroupId && (!oldGroupId || oldGroupId !== newGroupId)) {
          // Si l'addition passe a ce groupe (nouveau groupe ou changement de groupe)
          const updatedOptions = [...groupOptions, updatedAddition];
          return {
            ...group,
            options: updatedOptions,
            additions: updatedOptions,
            options_count: updatedOptions.length
          };
        }
        
        return group;
      });

      return {
        ...item,
        additions: updatedAdditions,
        option_groups: updatedGroups
      };
    });
  }, [updateMenuItemLocal]);

  const addAdditionLocal = useCallback((itemId: string, newAddition: Addition, groupId?: string) => {
    updateMenuItemLocal(itemId, (item) => {
      // Utiliser option_group_id de l'addition ou le parametre groupId
      const targetGroupId = newAddition.option_group_id || groupId;
      
      // Toujours ajouter a item.additions (le backend stocke toutes les additions ici)
      const updatedAdditions = [...(item.additions || []), newAddition];
      
      if (targetGroupId) {
        // Ajouter au groupe specifique
        const updatedGroups = (item.option_groups || []).map((group) => {
          if (group.id === targetGroupId) {
            const groupOptions = resolveGroupOptions(item, group);
            // Verifier que l'addition n'est pas deja dans le groupe
            const alreadyInGroup = groupOptions.some((opt) => opt.id === newAddition.id);
            if (!alreadyInGroup) {
              const updatedOptions = [...groupOptions, newAddition];
              return {
                ...group,
                options: updatedOptions,
                additions: updatedOptions,
                options_count: updatedOptions.length
              };
            }
            return group;
          }
          return group;
        });
        return {
          ...item,
          option_groups: updatedGroups,
          additions: updatedAdditions
        };
      } else {
        // Ajouter comme addition autonome (sans groupe)
        return {
          ...item,
          additions: updatedAdditions
        };
      }
    });
  }, [updateMenuItemLocal]);

  const removeAdditionLocal = useCallback((itemId: string, additionId: string) => {
    updateMenuItemLocal(itemId, (item) => {
      // Retirer de item.additions d'abord
      const updatedAdditions = (item.additions || []).filter((addition) => addition.id !== additionId);

      // Creer un item temporaire avec les additions mises a jour pour resolveGroupOptions
      const itemWithUpdatedAdditions = {
        ...item,
        additions: updatedAdditions
      };

      // Retirer des groupes d'options en utilisant l'item avec les additions mises a jour
      const updatedGroups = (item.option_groups || []).map((group) => {
        const groupOptions = resolveGroupOptions(itemWithUpdatedAdditions, group);
        const hasAddition = groupOptions.some((opt) => opt.id === additionId);
        if (hasAddition) {
          const updatedOptions = groupOptions.filter((opt) => opt.id !== additionId);
          return {
            ...group,
            options: updatedOptions,
            additions: updatedOptions,
            options_count: updatedOptions.length
          };
        }
        return group;
      });

      return {
        ...item,
        additions: updatedAdditions,
        option_groups: updatedGroups
      };
    });
  }, [updateMenuItemLocal]);

  // Fonctions pour les categories
  const updateCategoryLocal = useCallback((categoryId: string, updater: (category: FoodCategory) => FoodCategory) => {
    updateMenuLocal((menu) => {
      const updatedCategories = menu.categories.map((category) => {
        if (category.id === categoryId) {
          return updater(category);
        }
        return category;
      });
      return { ...menu, categories: updatedCategories };
    });
  }, [updateMenuLocal]);

  const addCategoryLocal = useCallback((newCategory: FoodCategory) => {
    updateMenuLocal((menu) => {
      return {
        ...menu,
        categories: [...menu.categories, newCategory]
      };
    });
  }, [updateMenuLocal]);

  const removeCategoryLocal = useCallback((categoryId: string) => {
    updateMenuLocal((menu) => {
      return {
        ...menu,
        categories: menu.categories.filter((category) => category.id !== categoryId)
      };
    });
  }, [updateMenuLocal]);

  const loadPromotions = useCallback(async () => {
    if (!restaurantId) return;
    setPromotionLoading(true);
    setPromotionError('');
    try {
      const response = await apiClient.get('/admin/promotions', {
        params: { restaurant_id: restaurantId, nocache: 'true' }
      });
      const data = response.data?.data;
      setPromotionOptions(Array.isArray(data) ? data : []);
    } catch (err: unknown) {
      setPromotionError(getApiErrorMessage(err, 'Erreur lors du chargement des promotions'));
    } finally {
      setPromotionLoading(false);
    }
  }, [restaurantId]);

  const loadPrinters = useCallback(async () => {
    if (!restaurantId) return;
    setPrintersLoading(true);
    setPrinterError('');
    try {
      const res = await apiClient.get(`/restaurant/admin/printers/${restaurantId}`);
      setPrinters(Array.isArray(res.data?.data) ? res.data.data : []);
    } catch (err: unknown) {
      setPrinterError(getApiErrorMessage(err, 'Erreur chargement imprimantes'));
    } finally {
      setPrintersLoading(false);
    }
  }, [restaurantId]);

  React.useEffect(() => {
    loadMenu();
    loadPromotions();
    loadPrinters();
  }, [loadMenu, loadPromotions, loadPrinters]);

  const openPrinterCreate = useCallback(() => {
    setPrinterModalMode('create');
    setPrinterModalEdit(null);
    setPrinterForm({ name: '', type: 'general', connectionType: 'network', ip: '', port: '9100', localPort: 'LPT1', windowsPrinterName: '', is_enabled: true, paper_width_mm: '80' });
    setPrinterFormErrors({});
    setPrinterError('');
    setPrinterModalOpen(true);
  }, []);

  const openPrinterEdit = useCallback((p: RestaurantPrinter) => {
    setPrinterModalMode('edit');
    setPrinterModalEdit(p);
    const local = isLocalPrinterIp(p.ip);
    const win = isWindowsPrinterIp(p.ip);
    setPrinterForm({
      name: p.name,
      type: (p.type === 'bar' ? 'general' : p.type) as PrinterForm['type'],
      connectionType: win ? 'windows' : local ? 'local' : 'network',
      ip: win || local ? '' : p.ip,
      port: String(p.port ?? 9100),
      localPort: local ? p.ip : 'LPT1',
      windowsPrinterName: win ? getWindowsPrinterDisplayName(p.ip) : '',
      is_enabled: p.is_enabled,
      paper_width_mm: String(p.paper_width_mm ?? 80)
    });
    setPrinterFormErrors({});
    setPrinterError('');
    setPrinterModalOpen(true);
  }, []);

  const closePrinterModal = useCallback(() => {
    setPrinterModalOpen(false);
    setPrinterModalEdit(null);
    setPrinterError('');
  }, []);

  const handlePrinterSubmit = useCallback(async () => {
    const err: Record<string, string> = {};
    if (!printerForm.name.trim()) err.name = 'Nom requis';
    const isLocal = printerForm.connectionType === 'local';
    const isWindows = printerForm.connectionType === 'windows';
    if (isLocal) {
      if (!printerForm.localPort.trim()) err.localPort = 'Port local requis (ex. LPT1)';
    } else if (isWindows) {
      if (!printerForm.windowsPrinterName.trim()) err.windowsPrinterName = 'Nom de l\'imprimante requis (ex. xprinter 2)';
    } else {
      if (!printerForm.ip.trim()) err.ip = 'IP requise';
      const port = parseInt(printerForm.port, 10);
      if (isNaN(port) || port < 1 || port > 65535) err.port = 'Port entre 1 et 65535';
    }
    const pwm = parseInt(printerForm.paper_width_mm, 10);
    if (pwm !== 58 && pwm !== 80) err.paper_width_mm = '58 ou 80';
    setPrinterFormErrors(err);
    if (Object.keys(err).length) return;

    const ip = isWindows ? 'WIN:' + printerForm.windowsPrinterName.trim() : isLocal ? printerForm.localPort.trim() : printerForm.ip.trim();
    const port = isLocal || isWindows ? 9100 : parseInt(printerForm.port, 10);

    setPrinterSaving(true);
    setPrinterError('');
    try {
      if (printerModalMode === 'create') {
        await apiClient.post('/restaurant/admin/printers', {
          restaurant_id: restaurantId,
          name: printerForm.name.trim(),
          type: printerForm.type,
          ip,
          port,
          is_enabled: printerForm.is_enabled,
          paper_width_mm: pwm
        });
        showNotification('Imprimante ajoutee');
      } else if (printerModalEdit) {
        await apiClient.put(`/restaurant/admin/printers/${printerModalEdit.id}`, {
          name: printerForm.name.trim(),
          type: printerForm.type,
          ip,
          port,
          is_enabled: printerForm.is_enabled,
          paper_width_mm: pwm
        });
        showNotification('Imprimante mise a jour');
      }
      closePrinterModal();
      loadPrinters();
    } catch (e: unknown) {
      setPrinterError(getApiErrorMessage(e, 'Erreur lors de l\'enregistrement'));
    } finally {
      setPrinterSaving(false);
    }
  }, [printerForm, printerModalMode, printerModalEdit, restaurantId, closePrinterModal, loadPrinters, showNotification]);

  const handlePrinterDelete = useCallback(async (p: RestaurantPrinter) => {
    if (!window.confirm(`Supprimer l'imprimante "${p.name}" ?`)) return;
    setPrinterSaving(true);
    try {
      await apiClient.delete(`/restaurant/admin/printers/${p.id}`);
      showNotification('Imprimante supprimee');
      loadPrinters();
    } catch (e: unknown) {
      showNotification(getApiErrorMessage(e, 'Erreur suppression'), 'error');
    } finally {
      setPrinterSaving(false);
    }
  }, [loadPrinters, showNotification]);

  const handlePrinterTest = useCallback(async (p: RestaurantPrinter) => {
    setPrinterTestingId(p.id);
    setPrinterError('');
    try {
      await apiClient.post(`/restaurant/admin/printers/${p.id}/test`);
      showNotification('Ticket de test envoye a ' + p.name);
    } catch (e: unknown) {
      showNotification(getApiErrorMessage(e, 'Echec du test d\'impression'), 'error');
    } finally {
      setPrinterTestingId(null);
    }
  }, [showNotification]);

  React.useEffect(() => {
    if (categoryImagePreview && categoryImagePreview.startsWith('blob:')) {
      return () => URL.revokeObjectURL(categoryImagePreview);
    }
    return undefined;
  }, [categoryImagePreview]);

  React.useEffect(() => {
    if (itemImagePreview && itemImagePreview.startsWith('blob:')) {
      return () => URL.revokeObjectURL(itemImagePreview);
    }
    return undefined;
  }, [itemImagePreview]);

  const restaurant = menu?.restaurant;
  const categories = useMemo(() => menu?.categories || [], [menu]);
  const sortedCategories = useMemo(() => {
    return [...categories].sort((a, b) => {
      const ao = a.ordre_affichage ?? Number.MAX_SAFE_INTEGER;
      const bo = b.ordre_affichage ?? Number.MAX_SAFE_INTEGER;
      if (ao !== bo) return ao - bo;
      return (a.nom || '').localeCompare(b.nom || '');
    });
  }, [categories]);

  const menuStats = useMemo(() => {
    const items = sortedCategories.flatMap((category) => category.items || []);
    const totalItems = items.length;
    const availableItems = items.filter((item) => item.is_available).length;
    const totalAdditions = items.reduce((sum, item) => sum + getAllAdditions(item).length, 0);

    return {
      totalCategories: sortedCategories.length,
      totalItems,
      availableItems,
      unavailableItems: totalItems - availableItems,
      totalAdditions
    };
  }, [sortedCategories]);

  const visibleCategories = useMemo(() => {
    const query = menuQuery.trim().toLowerCase();
    const hasSearch = query.length > 0;

    const matches = (value?: string | null) =>
      !hasSearch ? true : (value || '').toLowerCase().includes(query);

    const availabilityPredicate = (item: MenuItem) => {
      if (availabilityFilter === 'available') return item.is_available;
      if (availabilityFilter === 'unavailable') return !item.is_available;
      return true;
    };

    const itemMatchesQuery = (item: MenuItem) => {
      if (!hasSearch) return true;
      if (matches(item.nom) || matches(item.description)) return true;
      if (item.promotions?.some((promo) => matches(promo.title) || matches(promo.badge_text))) {
        return true;
      }
      if (
        item.option_groups?.some((group) =>
          matches(group.nom) ||
          matches(group.description) ||
          resolveGroupOptions(item, group).some(
            (addition) => matches(addition.nom) || matches(addition.description)
          )
        )
      ) {
        return true;
      }
      if (item.additions?.some((addition) => matches(addition.nom) || matches(addition.description))) {
        return true;
      }
      return false;
    };

    return sortedCategories
      .map((category) => {
        const baseItems = (category.items || []).filter(availabilityPredicate);
        if (!hasSearch) {
          return { ...category, items: baseItems };
        }

        const categoryMatches = matches(category.nom) || matches(category.description);
        if (categoryMatches) {
          return { ...category, items: baseItems };
        }

        const items = baseItems.filter(itemMatchesQuery);
        if (items.length === 0) return null;
        return { ...category, items };
      })
      .filter(Boolean) as FoodCategory[];
  }, [sortedCategories, menuQuery, availabilityFilter]);

  const visibleItemsCount = useMemo(() => {
    return visibleCategories.reduce((sum, category) => sum + (category.items?.length ?? 0), 0);
  }, [visibleCategories]);

  const hasFilters = menuQuery.trim().length > 0 || availabilityFilter !== 'all';
  // Filtrer les groupes virtuels (commencant par "ungrouped-") du selecteur
  const additionOptionGroups = (additionModalItem?.option_groups || []).filter(
    (group) => !group.id?.startsWith('ungrouped-')
  );

  const editablePromotions = useMemo(() => {
    const allowedTypes = new Set(['percentage', 'amount', 'free_delivery', 'other']);
    return [...promotionOptions]
      .filter((promotion) => {
        const type = String(promotion.type || '').toLowerCase();
        const hasAllowedType = !type || allowedTypes.has(type);
        const canTargetItem = isMenuItemScopedPromotion(promotion);
        return hasAllowedType && canTargetItem && !promotion.menu_item_id;
      })
      .sort((a, b) => {
        const aInactive = a.is_active === false ? 1 : 0;
        const bInactive = b.is_active === false ? 1 : 0;
        if (aInactive !== bInactive) return aInactive - bInactive;
        return getPromotionLabel(a).localeCompare(getPromotionLabel(b), 'fr');
      });
  }, [promotionOptions]);

  const linkedPromotion = useMemo(() => {
    if (!promotionModalItem) return null;
    return findLinkedPromotion(promotionOptions, String(promotionModalItem.id));
  }, [promotionModalItem, promotionOptions]);

  const lockedPromotion = useMemo(() => {
    if (!linkedPromotion) return null;
    if (linkedPromotion.menu_item_id) return linkedPromotion;
    if (!editablePromotions.some((promo) => promo.id === linkedPromotion.id)) {
      return linkedPromotion;
    }
    return null;
  }, [linkedPromotion, editablePromotions]);

  const currentEditablePromotionId = useMemo(() => {
    if (linkedPromotion && editablePromotions.some((promo) => promo.id === linkedPromotion.id)) {
      return linkedPromotion.id;
    }
    return '';
  }, [linkedPromotion, editablePromotions]);

  const currentPromotionId = useMemo(
    () => (lockedPromotion?.id ? lockedPromotion.id : currentEditablePromotionId),
    [lockedPromotion, currentEditablePromotionId]
  );

  const promotionSelectOptions = useMemo(() => {
    const options = [...editablePromotions];
    if (lockedPromotion && !options.some((promo) => promo.id === lockedPromotion.id)) {
      options.unshift(lockedPromotion);
    }
    return options;
  }, [editablePromotions, lockedPromotion]);

  React.useEffect(() => {
    if (!promotionModalOpen || !promotionModalItem) return;
    setPromotionSelection((prev) => (prev ? prev : currentPromotionId || ''));
  }, [promotionModalOpen, promotionModalItem, currentPromotionId]);

  const resetCategoryImageState = () => {
    setCategoryImagePreview(null);
    setCategoryImageError('');
    setCategoryImageUploading(false);
  };

  const resetItemImageState = () => {
    setItemImagePreview(null);
    setItemImageError('');
    setItemImageUploading(false);
  };

  const closeModal = () => {
    setModal('');
    setSelectedCategory(null);
    setSelectedItem(null);
    setModalError('');
    resetCategoryImageState();
    resetItemImageState();
  };

  const openCreateCategory = () => {
    setSelectedCategory(null);
    setCategoryForm({ nom: '', description: '', icone_url: '', ordre_affichage: '' });
    setModalError('');
    resetCategoryImageState();
    setModal('create-category');
  };

  const openEditCategory = (category: FoodCategory) => {
    setSelectedCategory(category);
    setCategoryForm({
      nom: category.nom || '',
      description: category.description || '',
      icone_url: category.icone_url || '',
      ordre_affichage: category.ordre_affichage != null ? String(category.ordre_affichage) : ''
    });
    setModalError('');
    resetCategoryImageState();
    setModal('edit-category');
  };

  const openDeleteCategory = (category: FoodCategory) => {
    setSelectedCategory(category);
    setModalError('');
    setModal('delete-category');
  };

  const openCreateItem = (categoryId: string) => {
    setSelectedItem(null);
    setItemForm({
      category_id: categoryId,
      nom: '',
      description: '',
      prix: '',
      photo_url: '',
      temps_preparation: '',
      is_available: true
    });
    setModalError('');
    resetItemImageState();
    setModal('create-item');
  };

  const openEditItem = (item: MenuItem, fallbackCategoryId?: string) => {
    setSelectedItem(item);
    setItemForm({
      category_id: item.category_id || fallbackCategoryId || '',
      nom: item.nom || '',
      description: item.description || '',
      prix: String(item.prix ?? ''),
      photo_url: item.photo_url || '',
      temps_preparation: item.temps_preparation != null ? String(item.temps_preparation) : '',
      is_available: !!item.is_available
    });
    setModalError('');
    resetItemImageState();
    setModal('edit-item');
  };

  const openDeleteItem = (item: MenuItem) => {
    setSelectedItem(item);
    setModalError('');
    setModal('delete-item');
  };

  const handleCategoryImageUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setCategoryImageError('');
    if (!file.type.startsWith('image/')) {
      setCategoryImageError('Veuillez selectionner une image valide.');
      return;
    }
    if (file.size > MAX_IMAGE_BYTES) {
      setCategoryImageError("L'image ne doit pas depasser 5 MB.");
      return;
    }

    setCategoryImageUploading(true);
    try {
      const url = await uploadImageFile(file);
      setCategoryForm((p) => ({ ...p, icone_url: url }));
      setCategoryImagePreview(URL.createObjectURL(file));
    } catch (err: unknown) {
      const message =
        err instanceof Error && err.message ? err.message : "Erreur lors de l'upload.";
      setCategoryImageError(message);
    } finally {
      setCategoryImageUploading(false);
    }
  };

  const removeCategoryImage = () => {
    setCategoryForm((p) => ({ ...p, icone_url: '' }));
    setCategoryImagePreview(null);
    setCategoryImageError('');
  };

  const handleItemImageUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setItemImageError('');
    if (!file.type.startsWith('image/')) {
      setItemImageError('Veuillez selectionner une image valide.');
      return;
    }
    if (file.size > MAX_IMAGE_BYTES) {
      setItemImageError("L'image ne doit pas depasser 5 MB.");
      return;
    }

    setItemImageUploading(true);
    try {
      const url = await uploadImageFile(file);
      setItemForm((p) => ({ ...p, photo_url: url }));
      setItemImagePreview(URL.createObjectURL(file));
    } catch (err: unknown) {
      const message =
        err instanceof Error && err.message ? err.message : "Erreur lors de l'upload.";
      setItemImageError(message);
    } finally {
      setItemImageUploading(false);
    }
  };

  const removeItemImage = () => {
    setItemForm((p) => ({ ...p, photo_url: '' }));
    setItemImagePreview(null);
    setItemImageError('');
  };

  const onCreateCategory = async () => {
    if (!restaurantId) return;
    setSaving(true);
    setModalError('');
    try {
      const response = await apiClient.post(`/api/v1/food-categories/admin/restaurant/${restaurantId}`, {
        nom: categoryForm.nom,
        description: categoryForm.description || undefined,
        icone_url: categoryForm.icone_url || undefined,
        ordre_affichage: parseNumber(categoryForm.ordre_affichage)
      });
      const newCategory = response.data?.data as FoodCategory | undefined;
      if (newCategory) {
        addCategoryLocal({
          ...newCategory,
          items: []
        });
      } else {
        await loadMenu();
      }
      closeModal();
    } catch (err: unknown) {
      setModalError(getApiErrorMessage(err, 'Erreur lors de la creation'));
    } finally {
      setSaving(false);
    }
  };

  const onUpdateCategory = async () => {
    if (!selectedCategory) return;
    setSaving(true);
    setModalError('');
    try {
      const response = await apiClient.put(`/api/v1/food-categories/admin/${selectedCategory.id}`, {
        nom: categoryForm.nom,
        description: categoryForm.description || undefined,
        icone_url: categoryForm.icone_url || undefined,
        ordre_affichage: parseNumber(categoryForm.ordre_affichage)
      });
      const updatedCategory = response.data?.data as FoodCategory | undefined;
      if (updatedCategory) {
        updateCategoryLocal(selectedCategory.id, (category) => ({
          ...category,
          ...updatedCategory
        }));
      } else {
        await loadMenu();
      }
      closeModal();
    } catch (err: unknown) {
      setModalError(getApiErrorMessage(err, 'Erreur lors de la mise a jour'));
    } finally {
      setSaving(false);
    }
  };

  const onDeleteCategory = async () => {
    if (!selectedCategory) return;
    setSaving(true);
    setModalError('');
    try {
      await apiClient.delete(`/api/v1/food-categories/admin/${selectedCategory.id}`);
      removeCategoryLocal(selectedCategory.id);
      closeModal();
    } catch (err: unknown) {
      setModalError(getApiErrorMessage(err, 'Erreur lors de la suppression'));
      await loadMenu();
    } finally {
      setSaving(false);
    }
  };

  const onCreateItem = async () => {
    setSaving(true);
    setModalError('');
    try {
      if (!itemForm.category_id) {
        setModalError('Veuillez choisir une categorie.');
        return;
      }
      const prix = parseNumber(itemForm.prix);
      if (prix == null) {
        setModalError('Veuillez entrer un prix valide.');
        return;
      }
      const response = await apiClient.post(`/menuitem/admin/create`, {
        category_id: itemForm.category_id,
        nom: itemForm.nom,
        description: itemForm.description || undefined,
        prix,
        photo_url: itemForm.photo_url || undefined,
        temps_preparation: parseNumber(itemForm.temps_preparation),
        is_available: itemForm.is_available
      });
      const newItem = response.data?.data as MenuItem | undefined;
      if (newItem) {
        addMenuItemLocal(itemForm.category_id, {
          ...newItem,
          additions: [],
          option_groups: [],
          promotions: []
        });
      } else {
        await loadMenu();
      }
      closeModal();
    } catch (err: unknown) {
      setModalError(getApiErrorMessage(err, 'Erreur lors de la creation'));
    } finally {
      setSaving(false);
    }
  };

  const onUpdateItem = async () => {
    if (!selectedItem) return;
    setSaving(true);
    setModalError('');
    try {
      if (!itemForm.category_id) {
        setModalError('Veuillez choisir une categorie.');
        return;
      }
      const prix = parseNumber(itemForm.prix);
      if (prix == null) {
        setModalError('Veuillez entrer un prix valide.');
        return;
      }
      const response = await apiClient.put(`/menuitem/admin/update/${selectedItem.id}`, {
        category_id: itemForm.category_id,
        nom: itemForm.nom,
        description: itemForm.description || undefined,
        prix,
        photo_url: itemForm.photo_url || undefined,
        temps_preparation: parseNumber(itemForm.temps_preparation),
        is_available: itemForm.is_available
      });
      const updatedItem = response.data?.data as MenuItem | undefined;
      if (updatedItem) {
        // Si la categorie a change, deplacer l'item
        if (itemForm.category_id !== selectedItem.category_id) {
          removeMenuItemLocal(selectedItem.id);
          addMenuItemLocal(itemForm.category_id, {
            ...updatedItem,
            additions: selectedItem.additions || [],
            option_groups: selectedItem.option_groups || [],
            promotions: selectedItem.promotions || []
          });
        } else {
          updateMenuItemLocal(selectedItem.id, (item) => ({
            ...item,
            ...updatedItem,
            additions: item.additions || [],
            option_groups: item.option_groups || [],
            promotions: item.promotions || []
          }));
        }
      } else {
        await loadMenu();
      }
      closeModal();
    } catch (err: unknown) {
      setModalError(getApiErrorMessage(err, 'Erreur lors de la mise a jour'));
    } finally {
      setSaving(false);
    }
  };

  const onDeleteItem = async () => {
    if (!selectedItem) return;
    setSaving(true);
    setModalError('');
    try {
      await apiClient.delete(`/menuitem/admin/delete/${selectedItem.id}`);
      removeMenuItemLocal(selectedItem.id);
      closeModal();
    } catch (err: unknown) {
      setModalError(getApiErrorMessage(err, 'Erreur lors de la suppression'));
      await loadMenu();
    } finally {
      setSaving(false);
    }
  };

  const onToggleAvailability = async (itemId: string) => {
    setSaving(true);
    setError('');
    try {
      await apiClient.patch(`/menuitem/admin/toggle-availability/${itemId}`);
      // Mise a jour locale optimiste
      updateMenuItemLocal(itemId, (item) => ({
        ...item,
        is_available: !item.is_available
      }));
    } catch (err: unknown) {
      setError(getApiErrorMessage(err, "Erreur lors du changement d'etat"));
      // Recharger en cas d'erreur pour restaurer l'etat
      await loadMenu();
    } finally {
      setSaving(false);
    }
  };

  const openPromotionModal = (item: MenuItem) => {
    setPromotionModalItem(item);
    setPromotionSelection('');
    setPromotionModalError('');
    setPromotionCreateOpen(false);
    setPromotionCreateForm(defaultPromotionCreateForm);
    setPromotionCreateErrors({});
    setPromotionCreateError('');
    setPromotionModalOpen(true);
  };

  const closePromotionModal = () => {
    setPromotionModalOpen(false);
    setPromotionModalItem(null);
    setPromotionSelection('');
    setPromotionModalError('');
    setPromotionCreateOpen(false);
    setPromotionCreateForm(defaultPromotionCreateForm);
    setPromotionCreateErrors({});
    setPromotionCreateError('');
  };

  const updatePromotionMenuItems = async (
    promotion: PromotionOption,
    menuItemIds: string[],
    directMenuItemId?: string | null
  ) => {
    const payload: Record<string, unknown> = {
      menu_item_ids: menuItemIds
    };
    if (directMenuItemId !== undefined) {
      payload.menu_item_id = directMenuItemId;
    }
    await apiClient.put(`/admin/promotions/${promotion.id}`, payload);
  };

  const handlePromotionSave = async () => {
    if (!promotionModalItem) return;
    const currentPromotionId = lockedPromotion?.id || currentEditablePromotionId;
    if ((promotionSelection || '') === (currentPromotionId || '')) {
      closePromotionModal();
      return;
    }

    setPromotionSaving(true);
    setPromotionModalError('');
    try {
      const currentPromotion = currentPromotionId
        ? promotionOptions.find((promo) => promo.id === currentPromotionId) || lockedPromotion
        : null;

      if (currentPromotion) {
        const nextIds = getPromotionMenuItemIds(currentPromotion).filter(
          (id) => id !== promotionModalItem.id
        );
        const shouldClearDirect = Boolean(currentPromotion.menu_item_id);
        await updatePromotionMenuItems(
          currentPromotion,
          nextIds,
          shouldClearDirect ? null : undefined
        );
      }

      if (promotionSelection) {
        const nextPromotion =
          promotionOptions.find((promo) => promo.id === promotionSelection) ||
          editablePromotions.find((promo) => promo.id === promotionSelection);
        if (!nextPromotion) {
          throw new Error('Promotion introuvable');
        }
        const nextIds = getPromotionMenuItemIds(nextPromotion);
        if (!nextIds.includes(promotionModalItem.id)) {
          nextIds.push(promotionModalItem.id);
        }
        await updatePromotionMenuItems(nextPromotion, nextIds);
      }

      showNotification('Promotions mises a jour');
      closePromotionModal();
      await loadMenu();
      await loadPromotions();
    } catch (err: unknown) {
      setPromotionModalError(getApiErrorMessage(err, 'Erreur lors de la mise a jour des promotions'));
    } finally {
      setPromotionSaving(false);
    }
  };

  const handlePromotionCreate = async () => {
    if (!promotionModalItem) return;
    const errors: Record<string, string> = {};
    const title = promotionCreateForm.title.trim();
    const type = promotionCreateForm.type;

    if (!title) {
      errors.title = 'Le titre est obligatoire';
    }

    if (type === 'percentage' || type === 'amount') {
      const discountValue = parseNumber(promotionCreateForm.discount_value);
      if (discountValue === undefined || discountValue <= 0) {
        errors.discount_value = 'Valeur de reduction invalide';
      }
    }

    if (type === 'other' && !promotionCreateForm.custom_message.trim()) {
      errors.custom_message = 'Le message est obligatoire pour ce type';
    }

    if (promotionCreateForm.start_date && promotionCreateForm.end_date) {
      const start = new Date(promotionCreateForm.start_date);
      const end = new Date(promotionCreateForm.end_date);
      if (!(end > start)) {
        errors.end_date = 'La date de fin doit etre apres la date de debut';
      }
    }

    if (Object.keys(errors).length > 0) {
      setPromotionCreateErrors(errors);
      return;
    }

    setPromotionCreateSaving(true);
    setPromotionCreateError('');
    setPromotionCreateErrors({});
    try {
      const payload: Record<string, unknown> = {
        title,
        type,
        scope: 'menu_item',
        restaurant_id: restaurantId,
        is_active: promotionCreateForm.is_active
      };

      const badgeText = promotionCreateForm.badge_text.trim();
      if (badgeText) {
        payload.badge_text = badgeText;
      }

      const startDate = promotionCreateForm.start_date.trim();
      if (startDate) {
        payload.start_date = startDate;
      }

      const endDate = promotionCreateForm.end_date.trim();
      if (endDate) {
        payload.end_date = endDate;
      }

      const customMessage = promotionCreateForm.custom_message.trim();
      if (customMessage) {
        payload.custom_message = customMessage;
      }

      if (type === 'percentage' || type === 'amount') {
        payload.discount_value = parseNumber(promotionCreateForm.discount_value);
        if (type === 'amount' && promotionCreateForm.currency.trim()) {
          payload.currency = promotionCreateForm.currency.trim();
        }
      }
      payload.menu_item_ids = [promotionModalItem.id];

      const response = await apiClient.post('/admin/promotions', payload);
      const created = response.data?.data as PromotionOption | undefined;

      showNotification('Promotion creee');
      setPromotionCreateOpen(false);
      setPromotionCreateForm(defaultPromotionCreateForm);
      await loadMenu();
      await loadPromotions();

      if (created?.menu_item_id) {
        setPromotionSelection('');
      } else if (created?.id) {
        setPromotionSelection(String(created.id));
      }
    } catch (err: unknown) {
      setPromotionCreateError(getApiErrorMessage(err, 'Erreur lors de la creation de la promotion'));
    } finally {
      setPromotionCreateSaving(false);
    }
  };

  const openAdditionModal = (
    item: MenuItem,
    mode: AdditionModalMode,
    addition?: Addition,
    optionGroupId?: string
  ) => {
    setAdditionModalMode(mode);
    setAdditionModalItem(item);
    setAdditionModalAddition(addition || null);
    
    // Detecter si le groupe est virtuel (commence par "ungrouped-")
    // Les groupes virtuels ne doivent pas etre selectionnes dans le formulaire
    let groupId = addition?.option_group_id || optionGroupId || '';
    if (groupId.startsWith('ungrouped-')) {
      groupId = ''; // Traiter comme "Sans groupe"
    }
    
    setAdditionForm({
      nom: addition?.nom || '',
      description: addition?.description || '',
      prix: addition ? String(addition.prix) : '',
      is_available: addition?.is_available ?? true,
      option_group_id: groupId
    });
    setAdditionFormErrors({});
    setAdditionModalError('');
    setAdditionModalOpen(true);
  };

  const closeAdditionModal = () => {
    setAdditionModalOpen(false);
    setAdditionModalItem(null);
    setAdditionModalAddition(null);
    setAdditionModalError('');
  };

  const createAddition = async (menuItemId: string, payload: {
    nom: string;
    description?: string;
    prix: number;
    is_available: boolean;
    option_group_id?: string;
  }) => {
    const response = await apiClient.post(`/api/v1/additions/admin/create`, {
      restaurant_id: restaurantId,
      menu_item_id: menuItemId,
      ...payload
    });
    return response.data?.data as Addition | undefined;
  };

  const updateAddition = async (additionId: string, payload: {
    nom: string;
    description?: string;
    prix: number;
    is_available: boolean;
    option_group_id?: string;
  }) => {
    const response = await apiClient.put(`/api/v1/additions/admin/update/${additionId}`, {
      restaurant_id: restaurantId,
      ...payload
    });
    return response.data?.data as Addition | undefined;
  };

  const deleteAddition = async (additionId: string) => {
    await apiClient.delete(`/api/v1/additions/admin/delete/${additionId}`, {
      data: { restaurant_id: restaurantId }
    });
  };

  const handleAdditionSubmit = async () => {
    if (!additionModalItem) return;
    const errors: Record<string, string> = {};
    if (!additionForm.nom.trim()) {
      errors.nom = 'Le nom est obligatoire';
    }
    const prixValue = parseFloat(additionForm.prix);
    if (Number.isNaN(prixValue)) {
      errors.prix = 'Prix invalide';
    } else if (prixValue < 0) {
      errors.prix = 'Le prix doit etre positif';
    }

    if (Object.keys(errors).length > 0) {
      setAdditionFormErrors(errors);
      return;
    }

    setAdditionSaving(true);
    setAdditionModalError('');
    try {
      // Detecter si le groupe est virtuel (commence par "ungrouped-")
      // Les groupes virtuels n'existent pas en base de donnees, donc on ne doit pas envoyer option_group_id
      const groupId = additionForm.option_group_id?.trim() || '';
      const isVirtualGroup = groupId.startsWith('ungrouped-');
      
      const payload = {
        nom: additionForm.nom.trim(),
        description: additionForm.description.trim() || undefined,
        prix: prixValue,
        is_available: additionForm.is_available,
        option_group_id: (groupId && !isVirtualGroup) ? groupId : undefined
      };

      if (additionModalMode === 'create') {
        const createdAddition = await createAddition(additionModalItem.id, payload);
        if (createdAddition) {
          // Utiliser option_group_id de l'addition creee (retourne par le backend)
          addAdditionLocal(additionModalItem.id, createdAddition, createdAddition.option_group_id || additionForm.option_group_id || undefined);
        } else {
          // Fallback: recharger le menu si pas de reponse
          await loadMenu();
        }
        showNotification('Addition creee avec succes');
      } else if (additionModalAddition) {
        const updatedAddition = await updateAddition(additionModalAddition.id, payload);
        if (updatedAddition) {
          updateAdditionLocal(additionModalItem.id, additionModalAddition.id, () => updatedAddition);
        } else {
          // Fallback: mise a jour locale avec les donnees du formulaire
          updateAdditionLocal(additionModalItem.id, additionModalAddition.id, () => ({
            ...additionModalAddition,
            ...payload,
            option_group_id: payload.option_group_id || additionModalAddition.option_group_id
          }));
        }
        showNotification('Addition mise a jour');
      }

      closeAdditionModal();
    } catch (err: unknown) {
      setAdditionModalError(getApiErrorMessage(err, 'Erreur lors de la sauvegarde'));
    } finally {
      setAdditionSaving(false);
    }
  };

  const handleDeleteAddition = async (itemId: string, additionId: string) => {
    if (!window.confirm('Supprimer cette addition ?')) return;
    setAdditionSaving(true);
    setAdditionModalError('');
    try {
      await deleteAddition(additionId);
      removeAdditionLocal(itemId, additionId);
      showNotification('Addition supprimee');
    } catch (err: unknown) {
      setAdditionModalError(getApiErrorMessage(err, 'Erreur lors de la suppression'));
    } finally {
      setAdditionSaving(false);
    }
  };

  const openOptionGroupModal = (
    item: MenuItem,
    mode: OptionGroupModalMode,
    group?: OptionGroup
  ) => {
    setOptionGroupModalMode(mode);
    setOptionGroupModalItem(item);
    setOptionGroupModalGroup(group || null);
    setOptionGroupForm({
      nom: group?.nom || '',
      description: group?.description || '',
      is_required: group?.is_required ?? false,
      ordre_affichage: group?.ordre_affichage != null ? String(group.ordre_affichage) : ''
    });
    setOptionGroupFormErrors({});
    setOptionGroupModalError('');
    setOptionGroupModalOpen(true);
  };

  const closeOptionGroupModal = () => {
    setOptionGroupModalOpen(false);
    setOptionGroupModalItem(null);
    setOptionGroupModalGroup(null);
    setOptionGroupModalError('');
  };

  const createOptionGroup = async (menuItemId: string, payload: {
    nom: string;
    description?: string;
    is_required: boolean;
    ordre_affichage?: number;
  }) => {
    const response = await apiClient.post('/api/v1/option-groups/admin/create', {
      restaurant_id: restaurantId,
      menu_item_id: menuItemId,
      ...payload
    });
    return response.data?.data as OptionGroup | undefined;
  };

  const updateOptionGroup = async (groupId: string, payload: {
    nom: string;
    description?: string;
    is_required: boolean;
    ordre_affichage?: number;
  }) => {
    const response = await apiClient.put(`/api/v1/option-groups/admin/update/${groupId}`, {
      restaurant_id: restaurantId,
      ...payload
    });
    return response.data?.data as OptionGroup | undefined;
  };

  const deleteOptionGroup = async (groupId: string) => {
    await apiClient.delete(`/api/v1/option-groups/admin/delete/${groupId}`, {
      data: { restaurant_id: restaurantId }
    });
  };

  const handleOptionGroupSubmit = async () => {
    if (!optionGroupModalItem) return;
    const errors: Record<string, string> = {};
    if (!optionGroupForm.nom.trim()) {
      errors.nom = 'Le nom est obligatoire';
    }
    const ordreValue = optionGroupForm.ordre_affichage.trim()
      ? parseInt(optionGroupForm.ordre_affichage, 10)
      : undefined;
    if (optionGroupForm.ordre_affichage.trim() && Number.isNaN(ordreValue)) {
      errors.ordre_affichage = 'Ordre invalide';
    }

    if (Object.keys(errors).length > 0) {
      setOptionGroupFormErrors(errors);
      return;
    }

    setOptionGroupSaving(true);
    setOptionGroupModalError('');
    try {
      const payload = {
        nom: optionGroupForm.nom.trim(),
        description: optionGroupForm.description.trim() || undefined,
        is_required: optionGroupForm.is_required,
        ordre_affichage: ordreValue
      };

      if (optionGroupModalMode === 'create') {
        const createdGroup = await createOptionGroup(optionGroupModalItem.id, payload);
        if (createdGroup) {
          addOptionGroupLocal(optionGroupModalItem.id, {
            ...createdGroup,
            options: [],
            additions: [],
            options_count: 0
          });
        }
        showNotification('Groupe cree');
      } else if (optionGroupModalGroup) {
        const updatedGroup = await updateOptionGroup(optionGroupModalGroup.id, payload);
        if (updatedGroup) {
          updateOptionGroupLocal(optionGroupModalItem.id, optionGroupModalGroup.id, (group) => ({
            ...group,
            ...updatedGroup,
            options: group.options || [],
            additions: group.additions || [],
            options_count: group.options_count || 0
          }));
        } else {
          // Fallback: mise a jour locale avec les donnees du formulaire
          updateOptionGroupLocal(optionGroupModalItem.id, optionGroupModalGroup.id, (group) => ({
            ...group,
            nom: payload.nom,
            description: payload.description,
            is_required: payload.is_required,
            ordre_affichage: payload.ordre_affichage
          }));
        }
        showNotification('Groupe mis a jour');
      }

      closeOptionGroupModal();
    } catch (err: unknown) {
      setOptionGroupModalError(getApiErrorMessage(err, 'Erreur lors de la sauvegarde'));
    } finally {
      setOptionGroupSaving(false);
    }
  };

  const handleDeleteOptionGroup = async (itemId: string, groupId: string) => {
    if (!window.confirm('Supprimer ce groupe ?')) return;
    setOptionGroupSaving(true);
    setOptionGroupModalError('');
    try {
      await deleteOptionGroup(groupId);
      removeOptionGroupLocal(itemId, groupId);
      showNotification('Groupe supprime');
    } catch (err: unknown) {
      setOptionGroupModalError(getApiErrorMessage(err, 'Erreur lors de la suppression'));
    } finally {
      setOptionGroupSaving(false);
    }
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between gap-3">
        <button
          type="button"
          onClick={() => router.push('/admin/restaurants')}
          className="p-2 rounded-lg border border-gray-200 hover:bg-gray-50 dark:border-slate-700 dark:hover:bg-slate-800"
          title="Retour"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <button
          type="button"
          onClick={loadMenu}
          className="p-2 rounded-lg border border-gray-200 hover:bg-gray-50 dark:border-slate-700 dark:hover:bg-slate-800"
          title="Rafraichir"
          disabled={loading}
        >
          <RefreshCw className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {toast ? (
        <div
          className={`fixed right-4 top-4 z-[60] rounded-lg border px-4 py-3 text-sm shadow-lg ${
            toast.type === 'success'
              ? 'border-emerald-200 bg-emerald-50 text-emerald-900 dark:border-emerald-800 dark:bg-emerald-900/20 dark:text-emerald-100'
              : 'border-red-200 bg-red-50 text-red-900 dark:border-red-800 dark:bg-red-900/20 dark:text-red-100'
          }`}
        >
          {toast.message}
        </div>
      ) : null}

      {error ? (
        <div className="rounded-lg border border-red-200 bg-red-50 text-red-800 px-4 py-3 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
          {error}
        </div>
      ) : null}

      {additionModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-xl bg-white shadow-xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-slate-800">
              <div className="font-semibold text-gray-900 dark:text-slate-100">
                {additionModalMode === 'create' ? 'Ajouter une addition' : 'Modifier l&apos;addition'}
              </div>
              <button
                type="button"
                onClick={closeAdditionModal}
                className="rounded-lg p-2 hover:bg-gray-50 dark:hover:bg-slate-800"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-4 space-y-3">
              {additionModalError ? (
                <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
                  {additionModalError}
                </div>
              ) : null}

              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                  Nom
                </label>
                <input
                  value={additionForm.nom}
                  onChange={(e) =>
                    setAdditionForm((prev) => ({ ...prev, nom: e.target.value }))
                  }
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                  placeholder="Ex: Fromage supplementaire"
                />
                {additionFormErrors.nom ? (
                  <p className="text-xs text-red-500 mt-1">{additionFormErrors.nom}</p>
                ) : null}
              </div>

              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                  Groupe d&apos;options
                </label>
                <select
                  value={additionForm.option_group_id}
                  onChange={(e) =>
                    setAdditionForm((prev) => ({ ...prev, option_group_id: e.target.value }))
                  }
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                >
                  <option value="">Sans groupe (optionnel)</option>
                  {additionOptionGroups.map((group) => (
                    <option key={group.id} value={group.id}>
                      {group.nom}{group.is_required ? ' (obligatoire)' : ''}
                    </option>
                  ))}
                </select>
                {additionOptionGroups.length === 0 ? (
                  <p className="text-xs text-gray-500 mt-1">
                    Aucun groupe defini. Creez un groupe pour rendre des options obligatoires.
                  </p>
                ) : null}
              </div>

              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                  Prix (DA)
                </label>
                <input
                  value={additionForm.prix}
                  onChange={(e) =>
                    setAdditionForm((prev) => ({ ...prev, prix: e.target.value }))
                  }
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                  placeholder="250"
                  inputMode="decimal"
                />
                {additionFormErrors.prix ? (
                  <p className="text-xs text-red-500 mt-1">{additionFormErrors.prix}</p>
                ) : null}
              </div>

              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                  Description
                </label>
                <textarea
                  value={additionForm.description}
                  onChange={(e) =>
                    setAdditionForm((prev) => ({ ...prev, description: e.target.value }))
                  }
                  rows={3}
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                  placeholder="Optionnel"
                />
              </div>

              <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-slate-200">
                <input
                  type="checkbox"
                  checked={additionForm.is_available}
                  onChange={(e) =>
                    setAdditionForm((prev) => ({ ...prev, is_available: e.target.checked }))
                  }
                  className="w-4 h-4 text-green-600 rounded focus:ring-2 focus:ring-green-500"
                />
                Disponible
              </label>
            </div>

            <div className="flex flex-wrap items-center justify-end gap-2 border-t border-gray-100 px-4 py-3 dark:border-slate-800">
              <button
                type="button"
                onClick={closeAdditionModal}
                className="rounded-lg border border-gray-200 px-3 py-2 text-sm font-medium text-gray-900 hover:bg-gray-50 dark:border-slate-700 dark:text-slate-100 dark:hover:bg-slate-800"
                disabled={additionSaving}
              >
                Annuler
              </button>

              <button
                type="button"
                onClick={handleAdditionSubmit}
                className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60"
                disabled={additionSaving}
              >
                <Save className="h-4 w-4" />
                {additionModalMode === 'create' ? 'Ajouter' : 'Enregistrer'}
              </button>
            </div>
          </div>
        </div>
      )}
      {optionGroupModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-xl bg-white shadow-xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-slate-800">
              <div className="font-semibold text-gray-900 dark:text-slate-100">
                {optionGroupModalMode === 'create' ? 'Ajouter un groupe' : 'Modifier le groupe'}
              </div>
              <button
                type="button"
                onClick={closeOptionGroupModal}
                className="rounded-lg p-2 hover:bg-gray-50 dark:hover:bg-slate-800"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-4 space-y-3">
              {optionGroupModalError ? (
                <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
                  {optionGroupModalError}
                </div>
              ) : null}

              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                  Nom
                </label>
                <input
                  value={optionGroupForm.nom}
                  onChange={(e) =>
                    setOptionGroupForm((prev) => ({ ...prev, nom: e.target.value }))
                  }
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                  placeholder="Ex: Taille"
                />
                {optionGroupFormErrors.nom ? (
                  <p className="text-xs text-red-500 mt-1">{optionGroupFormErrors.nom}</p>
                ) : null}
              </div>

              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                  Description
                </label>
                <textarea
                  value={optionGroupForm.description}
                  onChange={(e) =>
                    setOptionGroupForm((prev) => ({ ...prev, description: e.target.value }))
                  }
                  rows={3}
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                  placeholder="Optionnel"
                />
              </div>

              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                  Ordre d&apos;affichage
                </label>
                <input
                  value={optionGroupForm.ordre_affichage}
                  onChange={(e) =>
                    setOptionGroupForm((prev) => ({ ...prev, ordre_affichage: e.target.value }))
                  }
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                  placeholder="0"
                  inputMode="numeric"
                />
                {optionGroupFormErrors.ordre_affichage ? (
                  <p className="text-xs text-red-500 mt-1">{optionGroupFormErrors.ordre_affichage}</p>
                ) : null}
              </div>

              <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-slate-200">
                <input
                  type="checkbox"
                  checked={optionGroupForm.is_required}
                  onChange={(e) =>
                    setOptionGroupForm((prev) => ({ ...prev, is_required: e.target.checked }))
                  }
                  className="w-4 h-4 text-green-600 rounded focus:ring-2 focus:ring-green-500"
                />
                Groupe obligatoire
              </label>

              {/* Liste des options du groupe */}
              {optionGroupModalMode === 'edit' && optionGroupModalGroup && optionGroupModalItem && (
                <div className="mt-4 pt-4 border-t border-gray-200 dark:border-slate-700">
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-sm font-semibold text-gray-900 dark:text-slate-100">
                      Options du groupe ({resolveGroupOptions(optionGroupModalItem, optionGroupModalGroup).length})
                    </h3>
                    <button
                      type="button"
                      onClick={() => {
                        if (optionGroupModalItem) {
                          closeOptionGroupModal();
                          openAdditionModal(optionGroupModalItem, 'create', undefined, optionGroupModalGroup.id);
                        }
                      }}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-emerald-200 px-2.5 py-1.5 text-xs font-medium text-emerald-700 transition hover:bg-emerald-50 hover:border-emerald-300 dark:border-emerald-800 dark:text-emerald-200 dark:hover:bg-emerald-900/20"
                    >
                      <Plus className="h-4 w-4 shrink-0" />
                      Ajouter option
                    </button>
                  </div>
                  <div className="space-y-2 max-h-64 overflow-y-auto">
                    {resolveGroupOptions(optionGroupModalItem, optionGroupModalGroup).length > 0 ? (
                      resolveGroupOptions(optionGroupModalItem, optionGroupModalGroup).map((option) => (
                        <div
                          key={option.id}
                          className="flex items-center justify-between gap-2 rounded-lg border border-gray-200 bg-gray-50 p-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                        >
                          <div className="flex-1 min-w-0">
                            <div className="font-medium text-gray-900 dark:text-slate-100 truncate">
                              {option.nom}
                            </div>
                            <div className="flex items-center gap-2 mt-1">
                              <span className="text-xs text-gray-600 dark:text-slate-400">
                                {formatDA(option.prix)}
                              </span>
                              {option.is_available !== undefined && (
                                <span
                                  className={`text-[10px] px-1.5 py-0.5 rounded-full ${
                                    option.is_available
                                      ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-200'
                                      : 'bg-gray-100 text-gray-600 dark:bg-slate-700 dark:text-slate-400'
                                  }`}
                                >
                                  {option.is_available ? 'Disponible' : 'Indisponible'}
                                </span>
                              )}
                            </div>
                            {option.description && (
                              <div className="text-xs text-gray-500 dark:text-slate-400 mt-1 truncate">
                                {option.description}
                              </div>
                            )}
                          </div>
                          <div className="flex items-center gap-1.5 shrink-0">
                            <button
                              type="button"
                              onClick={() => {
                                if (optionGroupModalItem) {
                                  closeOptionGroupModal();
                                  openAdditionModal(optionGroupModalItem, 'edit', option, optionGroupModalGroup.id);
                                }
                              }}
                              className="inline-flex items-center gap-1 rounded-lg border border-slate-200 px-2 py-1 text-xs font-medium text-slate-700 transition hover:bg-slate-50 hover:border-slate-300 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
                              title="Modifier l'option"
                            >
                              <Edit className="h-4 w-4 shrink-0" />
                            </button>
                            <button
                              type="button"
                              onClick={async () => {
                                if (window.confirm(`Supprimer l'option "${option.nom}" ?`)) {
                                  try {
                                    await apiClient.delete(`/api/v1/additions/admin/delete/${option.id}`, {
                                      data: { restaurant_id: restaurantId }
                                    });
                                    if (optionGroupModalItem && optionGroupModalGroup) {
                                      // Calculer les donnees mises a jour localement avant la suppression
                                      const currentItem = menu?.categories
                                        .flatMap((cat) => cat.items || [])
                                        .find((item) => item.id === optionGroupModalItem.id);
                                      
                                      if (currentItem) {
                                        // Simuler la suppression locale pour obtenir les donnees mises a jour
                                        const updatedAdditions = (currentItem.additions || []).filter(
                                          (addition) => addition.id !== option.id
                                        );
                                        
                                        // Creer un item temporaire avec les additions mises a jour pour resolveGroupOptions
                                        const itemWithUpdatedAdditions = {
                                          ...currentItem,
                                          additions: updatedAdditions
                                        };
                                        
                                        // Mettre a jour les groupes d'options en utilisant l'item avec les additions mises a jour
                                        const updatedGroups = (currentItem.option_groups || []).map((group) => {
                                          if (group.id === optionGroupModalGroup.id) {
                                            const groupOptions = resolveGroupOptions(itemWithUpdatedAdditions, group);
                                            const updatedOptions = groupOptions.filter((opt) => opt.id !== option.id);
                                            return {
                                              ...group,
                                              options: updatedOptions,
                                              additions: updatedOptions,
                                              options_count: updatedOptions.length
                                            };
                                          }
                                          return group;
                                        });
                                        
                                        const updatedItem = {
                                          ...currentItem,
                                          additions: updatedAdditions,
                                          option_groups: updatedGroups
                                        };
                                        
                                        const updatedGroup = updatedGroups.find(
                                          (g) => g.id === optionGroupModalGroup.id
                                        );
                                        
                                        // Appliquer la suppression locale
                                        removeAdditionLocal(optionGroupModalItem.id, option.id);
                                        
                                        // Rouvrir immediatement le modal avec les donnees calculees (pas besoin d'attendre le state)
                                        if (updatedGroup) {
                                          openOptionGroupModal(updatedItem, 'edit', updatedGroup);
                                        } else {
                                          closeOptionGroupModal();
                                        }
                                      } else {
                                        // Fallback: supprimer et fermer le modal
                                        removeAdditionLocal(optionGroupModalItem.id, option.id);
                                        closeOptionGroupModal();
                                      }
                                    }
                                    showNotification('Option supprimee');
                                  } catch (err: unknown) {
                                    showNotification(getApiErrorMessage(err, 'Erreur lors de la suppression'), 'error');
                                  }
                                }
                              }}
                              className="inline-flex items-center gap-1 rounded-lg border border-red-200 px-2 py-1 text-xs font-medium text-red-600 transition hover:bg-red-50 hover:border-red-300 dark:border-red-800 dark:text-red-300 dark:hover:bg-red-900/20"
                              title="Supprimer l'option"
                            >
                              <Trash2 className="h-4 w-4 shrink-0" />
                            </button>
                          </div>
                        </div>
                      ))
                    ) : (
                      <div className="text-xs italic text-gray-500 dark:text-slate-400 py-4 text-center">
                        Aucune option dans ce groupe
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>

            <div className="flex flex-wrap items-center justify-end gap-2 border-t border-gray-100 px-4 py-3 dark:border-slate-800">
              <button
                type="button"
                onClick={closeOptionGroupModal}
                className="rounded-lg border border-gray-200 px-3 py-2 text-sm font-medium text-gray-900 hover:bg-gray-50 dark:border-slate-700 dark:text-slate-100 dark:hover:bg-slate-800"
                disabled={optionGroupSaving}
              >
                Annuler
              </button>

              <button
                type="button"
                onClick={handleOptionGroupSubmit}
                className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60"
                disabled={optionGroupSaving}
              >
                <Save className="h-4 w-4" />
                {optionGroupModalMode === 'create' ? 'Ajouter' : 'Enregistrer'}
              </button>
            </div>
          </div>
        </div>
      )}
      {promotionModalOpen && promotionModalItem ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-xl bg-white shadow-xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-slate-800">
              <div className="font-semibold text-gray-900 dark:text-slate-100">Promotions du plat</div>
              <button
                type="button"
                onClick={closePromotionModal}
                className="rounded-lg p-2 hover:bg-gray-50 dark:hover:bg-slate-800"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-4 space-y-3">
              {promotionModalError ? (
                <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
                  {promotionModalError}
                </div>
              ) : null}

              {promotionError ? (
                <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
                  {promotionError}
                </div>
              ) : null}

              <div className="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-700 dark:border-slate-700 dark:bg-slate-800/50 dark:text-slate-200">
                Plat: <span className="font-medium">{promotionModalItem.nom}</span>
              </div>

              {lockedPromotion ? (
                <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800 dark:border-amber-900/40 dark:bg-amber-900/20 dark:text-amber-200">
                  {lockedPromotion.menu_item_id ? 'Promotion liee via menu_item_id' : 'Promotion actuelle'}
                  {`: ${getPromotionLabel(lockedPromotion)}`}
                  <div className="mt-1 text-[11px] text-amber-700 dark:text-amber-200">
                    Choisissez &quot;Aucune promotion&quot; pour la detacher ou liez une autre promotion.
                  </div>
                </div>
              ) : null}

              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                  Promotion associee
                </label>
                <select
                  value={promotionSelection}
                  onChange={(e) => setPromotionSelection(e.target.value)}
                  disabled={
                    promotionLoading ||
                    promotionSaving ||
                    promotionCreateSaving ||
                    promotionSelectOptions.length === 0
                  }
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                >
                  <option value="">Aucune promotion</option>
                  {promotionSelectOptions.map((promo) => (
                    <option key={promo.id} value={promo.id}>
                      {getPromotionLabel(promo)}
                      {promo.is_active === false ? ' (inactive)' : ''}
                      {lockedPromotion && promo.id === lockedPromotion.id ? ' (verrouillee)' : ''}
                    </option>
                  ))}
                </select>
                {promotionLoading ? (
                  <p className="mt-1 text-xs text-gray-500 dark:text-slate-400">
                    Chargement des promotions...
                  </p>
                ) : null}
                {!promotionLoading && editablePromotions.length === 0 && !lockedPromotion ? (
                  <p className="mt-1 text-xs text-gray-500 dark:text-slate-400">
                    Aucune promotion modifiable pour ce restaurant.
                  </p>
                ) : null}
              </div>

              <div className="rounded-lg border border-gray-200 bg-white/80 p-3 shadow-sm dark:border-slate-700 dark:bg-slate-900/40">
                <div className="flex items-center justify-between">
                  <div className="text-sm font-semibold text-gray-900 dark:text-slate-100">
                    Nouvelle promotion
                  </div>
                  <button
                    type="button"
                    onClick={() => setPromotionCreateOpen((prev) => !prev)}
                    className="rounded-lg border border-gray-200 px-2.5 py-1 text-xs font-medium text-gray-700 hover:bg-gray-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    disabled={promotionCreateSaving}
                  >
                    {promotionCreateOpen ? 'Masquer' : 'Ajouter'}
                  </button>
                </div>

                {promotionCreateOpen ? (
                  <div className="mt-3 space-y-3">
                    {promotionCreateError ? (
                      <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
                        {promotionCreateError}
                      </div>
                    ) : null}

                    <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                      <div className="sm:col-span-2">
                        <label className="text-xs font-semibold text-gray-600 dark:text-slate-300">
                          Titre
                        </label>
                        <input
                          value={promotionCreateForm.title}
                          onChange={(e) =>
                            setPromotionCreateForm((prev) => ({ ...prev, title: e.target.value }))
                          }
                          className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                          placeholder="Ex: -20% sur le tacos"
                        />
                        {promotionCreateErrors.title ? (
                          <p className="mt-1 text-xs text-red-500">{promotionCreateErrors.title}</p>
                        ) : null}
                      </div>

                      <div>
                        <label className="text-xs font-semibold text-gray-600 dark:text-slate-300">
                          Type
                        </label>
                        <select
                          value={promotionCreateForm.type}
                          onChange={(e) =>
                            setPromotionCreateForm((prev) => ({
                              ...prev,
                              type: e.target.value as PromotionCreateForm['type']
                            }))
                          }
                          className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        >
                          <option value="percentage">Pourcentage</option>
                          <option value="amount">Montant</option>
                          <option value="free_delivery">Livraison gratuite</option>
                          <option value="other">Autre</option>
                        </select>
                      </div>

                      {promotionCreateForm.type === 'amount' ? (
                        <div>
                          <label className="text-xs font-semibold text-gray-600 dark:text-slate-300">
                            Devise
                          </label>
                          <input
                            value={promotionCreateForm.currency}
                            onChange={(e) =>
                              setPromotionCreateForm((prev) => ({ ...prev, currency: e.target.value }))
                            }
                            className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                            placeholder="DZD"
                          />
                        </div>
                      ) : null}

                      {(promotionCreateForm.type === 'percentage' ||
                        promotionCreateForm.type === 'amount') && (
                        <div>
                          <label className="text-xs font-semibold text-gray-600 dark:text-slate-300">
                            Valeur reduction
                          </label>
                          <input
                            value={promotionCreateForm.discount_value}
                            onChange={(e) =>
                              setPromotionCreateForm((prev) => ({
                                ...prev,
                                discount_value: e.target.value
                              }))
                            }
                            className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                            placeholder={promotionCreateForm.type === 'percentage' ? '20' : '300'}
                            inputMode="decimal"
                          />
                          {promotionCreateErrors.discount_value ? (
                            <p className="mt-1 text-xs text-red-500">
                              {promotionCreateErrors.discount_value}
                            </p>
                          ) : null}
                        </div>
                      )}

                      {promotionCreateForm.type === 'other' && (
                        <div className="sm:col-span-2">
                          <label className="text-xs font-semibold text-gray-600 dark:text-slate-300">
                            Message
                          </label>
                          <textarea
                            value={promotionCreateForm.custom_message}
                            onChange={(e) =>
                              setPromotionCreateForm((prev) => ({
                                ...prev,
                                custom_message: e.target.value
                              }))
                            }
                            rows={3}
                            className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                            placeholder="Ex: Offre du jour"
                          />
                          {promotionCreateErrors.custom_message ? (
                            <p className="mt-1 text-xs text-red-500">
                              {promotionCreateErrors.custom_message}
                            </p>
                          ) : null}
                        </div>
                      )}

                      <div className="sm:col-span-2">
                        <label className="text-xs font-semibold text-gray-600 dark:text-slate-300">
                          Badge (optionnel)
                        </label>
                        <input
                          value={promotionCreateForm.badge_text}
                          onChange={(e) =>
                            setPromotionCreateForm((prev) => ({
                              ...prev,
                              badge_text: e.target.value
                            }))
                          }
                          className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                          placeholder="Ex: -20%"
                        />
                      </div>

                      <div>
                        <label className="text-xs font-semibold text-gray-600 dark:text-slate-300">
                          Debut
                        </label>
                        <input
                          type="datetime-local"
                          value={promotionCreateForm.start_date}
                          onChange={(e) =>
                            setPromotionCreateForm((prev) => ({
                              ...prev,
                              start_date: e.target.value
                            }))
                          }
                          className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        />
                      </div>
                      <div>
                        <label className="text-xs font-semibold text-gray-600 dark:text-slate-300">
                          Fin
                        </label>
                        <input
                          type="datetime-local"
                          value={promotionCreateForm.end_date}
                          onChange={(e) =>
                            setPromotionCreateForm((prev) => ({
                              ...prev,
                              end_date: e.target.value
                            }))
                          }
                          className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        />
                        {promotionCreateErrors.end_date ? (
                          <p className="mt-1 text-xs text-red-500">
                            {promotionCreateErrors.end_date}
                          </p>
                        ) : null}
                      </div>
                    </div>

                    <label className="flex items-center gap-2 text-xs text-gray-600 dark:text-slate-300">
                      <input
                        type="checkbox"
                        checked={promotionCreateForm.is_active}
                        onChange={(e) =>
                          setPromotionCreateForm((prev) => ({
                            ...prev,
                            is_active: e.target.checked
                          }))
                        }
                        className="h-4 w-4 text-amber-600 rounded focus:ring-2 focus:ring-amber-500"
                      />
                      Promotion active
                    </label>

                    <div className="flex items-center justify-end">
                      <button
                        type="button"
                        onClick={handlePromotionCreate}
                        className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60"
                        disabled={promotionCreateSaving}
                      >
                        <Plus className="h-4 w-4" />
                        {promotionCreateSaving ? 'Creation...' : 'Creer et lier'}
                      </button>
                    </div>
                  </div>
                ) : null}
              </div>
            </div>

            <div className="flex flex-wrap items-center justify-end gap-2 border-t border-gray-100 px-4 py-3 dark:border-slate-800">
              <button
                type="button"
                onClick={closePromotionModal}
                className="rounded-lg border border-gray-200 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-60 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                disabled={promotionSaving || promotionCreateSaving}
              >
                Annuler
              </button>
              <button
                type="button"
                onClick={handlePromotionSave}
                className="inline-flex items-center gap-2 rounded-lg bg-amber-600 px-3 py-2 text-sm font-medium text-white hover:bg-amber-700 disabled:opacity-60"
                disabled={
                  promotionSaving ||
                  promotionLoading ||
                  promotionCreateSaving ||
                  promotionSelection === currentPromotionId
                }
              >
                {promotionSaving ? 'Enregistrement...' : 'Enregistrer'}
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {printerModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-md rounded-xl bg-white shadow-xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-slate-800">
              <div className="font-semibold text-gray-900 dark:text-slate-100">
                {printerModalMode === 'create' ? 'Ajouter une imprimante' : 'Modifier l\'imprimante'}
              </div>
              <button type="button" onClick={closePrinterModal} className="rounded-lg p-2 hover:bg-gray-50 dark:hover:bg-slate-800">
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="p-4 space-y-3">
              {printerError ? (
                <div className="rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
                  {printerError}
                </div>
              ) : null}
              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">Nom</label>
                <input
                  value={printerForm.name}
                  onChange={(e) => setPrinterForm((prev) => ({ ...prev, name: e.target.value }))}
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                  placeholder="Ex: Caisse 1, Cuisine"
                />
                {printerFormErrors.name ? <p className="text-xs text-red-500 mt-1">{printerFormErrors.name}</p> : null}
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">Type</label>
                <select
                  value={printerForm.type}
                  onChange={(e) => setPrinterForm((prev) => ({ ...prev, type: e.target.value as PrinterForm['type'] }))}
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                >
                  <option value="general">General</option>
                  <option value="caisse">Caisse</option>
                  <option value="cuisine">Cuisine</option>
                </select>
              </div>
              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">Connexion</label>
                <select
                  value={printerForm.connectionType}
                  onChange={(e) => setPrinterForm((prev) => ({ ...prev, connectionType: e.target.value as 'network' | 'local' | 'windows' }))}
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                >
                  <option value="network">Reseau (IP + port 9100)</option>
                  <option value="local">Locale (LPT/COM sur le PC du serveur)</option>
                  <option value="windows">Imprimante Windows (par nom)</option>
                </select>
                <p className="mt-0.5 text-xs text-gray-500 dark:text-slate-400">
                  {printerForm.connectionType === 'local' ? 'Imprimante branchee en LPT ou COM sur le PC ou tourne le backend (Windows).' : printerForm.connectionType === 'windows' ? 'Imprimante installee avec pilote : saisir le nom exact comme dans Parametres &gt; Imprimantes (ex. xprinter 2).' : 'Imprimante reseau Ethernet/WiFi avec une IP.'}
                </p>
              </div>
              {printerForm.connectionType === 'local' ? (
                <div>
                  <label className="text-sm font-medium text-gray-700 dark:text-slate-200">Port local</label>
                  <select
                    value={printerForm.localPort}
                    onChange={(e) => setPrinterForm((prev) => ({ ...prev, localPort: e.target.value }))}
                    className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                  >
                    <option value="LPT1">LPT1</option>
                    <option value="LPT2">LPT2</option>
                    <option value="LPT3">LPT3</option>
                    <option value="COM1">COM1</option>
                    <option value="COM2">COM2</option>
                    <option value="COM3">COM3</option>
                    <option value="COM4">COM4</option>
                    <option value="USB001">USB001</option>
                    <option value="USB002">USB002</option>
                  </select>
                  {printerFormErrors.localPort ? <p className="text-xs text-red-500 mt-1">{printerFormErrors.localPort}</p> : null}
                </div>
              ) : printerForm.connectionType === 'windows' ? (
                <div>
                  <label className="text-sm font-medium text-gray-700 dark:text-slate-200">Nom de l&apos;imprimante Windows</label>
                  <input
                    value={printerForm.windowsPrinterName}
                    onChange={(e) => setPrinterForm((prev) => ({ ...prev, windowsPrinterName: e.target.value }))}
                    className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                    placeholder="Ex: xprinter 2, XP-80C (copy 1)"
                  />
                  {printerFormErrors.windowsPrinterName ? <p className="text-xs text-red-500 mt-1">{printerFormErrors.windowsPrinterName}</p> : null}
                </div>
              ) : (
                <>
                  <div>
                    <label className="text-sm font-medium text-gray-700 dark:text-slate-200">Adresse IP</label>
                    <input
                      value={printerForm.ip}
                      onChange={(e) => setPrinterForm((prev) => ({ ...prev, ip: e.target.value }))}
                      className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                      placeholder="192.168.1.100"
                    />
                    {printerFormErrors.ip ? <p className="text-xs text-red-500 mt-1">{printerFormErrors.ip}</p> : null}
                  </div>
                  <div>
                    <label className="text-sm font-medium text-gray-700 dark:text-slate-200">Port (RAW, souvent 9100)</label>
                    <input
                      value={printerForm.port}
                      onChange={(e) => setPrinterForm((prev) => ({ ...prev, port: e.target.value }))}
                      className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                      placeholder="9100"
                    />
                    {printerFormErrors.port ? <p className="text-xs text-red-500 mt-1">{printerFormErrors.port}</p> : null}
                  </div>
                </>
              )}
              <div>
                <label className="text-sm font-medium text-gray-700 dark:text-slate-200">Largeur papier (mm)</label>
                <select
                  value={printerForm.paper_width_mm}
                  onChange={(e) => setPrinterForm((prev) => ({ ...prev, paper_width_mm: e.target.value }))}
                  className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                >
                  <option value="58">58 mm</option>
                  <option value="80">80 mm</option>
                </select>
                {printerFormErrors.paper_width_mm ? <p className="text-xs text-red-500 mt-1">{printerFormErrors.paper_width_mm}</p> : null}
              </div>
              <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-slate-200">
                <input
                  type="checkbox"
                  checked={printerForm.is_enabled}
                  onChange={(e) => setPrinterForm((prev) => ({ ...prev, is_enabled: e.target.checked }))}
                  className="w-4 h-4 text-green-600 rounded focus:ring-2 focus:ring-green-500"
                />
                Imprimante activee (impression a chaque nouvelle commande)
              </label>
            </div>
            <div className="flex justify-end gap-2 border-t border-gray-100 px-4 py-3 dark:border-slate-800">
              <button type="button" onClick={closePrinterModal} className="rounded-lg border border-gray-200 px-3 py-2 text-sm font-medium dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800" disabled={printerSaving}>
                Annuler
              </button>
              <button type="button" onClick={handlePrinterSubmit} className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60" disabled={printerSaving}>
                <Save className="h-4 w-4" />
                {printerSaving ? 'Enregistrement...' : 'Enregistrer'}
              </button>
            </div>
          </div>
        </div>
      )}


      <div className="rounded-xl border border-gray-200 bg-white p-4 dark:bg-slate-900 dark:border-slate-700">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div className="min-w-0">
            <h1 className="text-xl font-bold text-gray-900 dark:text-slate-100">
              {restaurant?.name || 'Restaurant'}
            </h1>

            <div className="mt-1 space-y-1 text-sm text-gray-600 dark:text-slate-300">
              {restaurant?.address ? <div>{restaurant.address}</div> : null}
              {restaurant?.phone_number ? <div>{restaurant.phone_number}</div> : null}
              {restaurant?.email ? <div>{restaurant.email}</div> : null}
              {restaurant?.locale ? <div>Langue: {getLocaleLabel(restaurant.locale)}</div> : null}
            </div>

            <div className="mt-3 flex flex-wrap items-center gap-2 text-xs">
              <span className="rounded-full bg-slate-100 px-2 py-0.5 font-mono text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                ID: {restaurantId}
              </span>

              {restaurant?.home_categories?.length ? (
                <>
                  <span className="text-gray-500 dark:text-slate-400">Categories globales:</span>
                  {restaurant.home_categories.map((cat) => (
                    <span
                      key={cat.id}
                      className="rounded-full bg-indigo-50 px-2 py-0.5 font-medium text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-200"
                      title={cat.slug}
                    >
                      {cat.name}
                    </span>
                  ))}
                </>
              ) : null}

              {restaurant?.categories?.length ? (
                <span className="text-gray-500 dark:text-slate-400">
                  Slugs: {restaurant.categories.join(', ')}
                </span>
              ) : null}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            <div className="rounded-lg border border-gray-200 bg-white p-3 text-center dark:border-slate-700 dark:bg-slate-950">
              <div className="text-xs text-gray-500 dark:text-slate-400">Categories</div>
              <div className="text-lg font-bold text-gray-900 dark:text-slate-100">
                {menuStats.totalCategories}
              </div>
            </div>
            <div className="rounded-lg border border-gray-200 bg-white p-3 text-center dark:border-slate-700 dark:bg-slate-950">
              <div className="text-xs text-gray-500 dark:text-slate-400">Plats</div>
              <div className="text-lg font-bold text-gray-900 dark:text-slate-100">
                {menuStats.totalItems}
              </div>
            </div>
            <div className="rounded-lg border border-gray-200 bg-white p-3 text-center dark:border-slate-700 dark:bg-slate-950">
              <div className="text-xs text-gray-500 dark:text-slate-400">Disponibles</div>
              <div className="text-lg font-bold text-emerald-700 dark:text-emerald-200">
                {menuStats.availableItems}
              </div>
            </div>
            <div className="rounded-lg border border-gray-200 bg-white p-3 text-center dark:border-slate-700 dark:bg-slate-950">
              <div className="text-xs text-gray-500 dark:text-slate-400">Indisponibles</div>
              <div className="text-lg font-bold text-gray-900 dark:text-slate-100">
                {menuStats.unavailableItems}
              </div>
            </div>
          </div>
        </div>

        <div className="mt-4 flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
          <div className="grid w-full grid-cols-1 gap-3 sm:max-w-xl sm:grid-cols-2">
            <div>
              <label className="text-xs font-semibold text-gray-500 dark:text-slate-400">
                Rechercher (plat / addition / promo)
              </label>
              <input
                value={menuQuery}
                onChange={(e) => setMenuQuery(e.target.value)}
                className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                placeholder="Ex: tacos, fromage, -20%..."
              />
            </div>

            <div>
              <label className="text-xs font-semibold text-gray-500 dark:text-slate-400">
                Disponibilite
              </label>
              <select
                value={availabilityFilter}
                onChange={(e) =>
                  setAvailabilityFilter(e.target.value as 'all' | 'available' | 'unavailable')
                }
                className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
              >
                <option value="all">Tous les plats</option>
                <option value="available">Disponibles</option>
                <option value="unavailable">Indisponibles</option>
              </select>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <button
              type="button"
              onClick={() => {
                setMenuQuery('');
                setAvailabilityFilter('all');
              }}
              className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-slate-50/80 px-3 py-2 text-sm font-medium text-slate-600 transition hover:bg-slate-100 hover:border-slate-300 dark:border-slate-600 dark:bg-slate-800/50 dark:text-slate-300 dark:hover:bg-slate-800"
              disabled={loading || saving}
              title="Vider les filtres"
            >
              <RotateCcw className="h-4 w-4" />
              Reinitialiser
            </button>
            <span className="hidden h-5 w-px bg-slate-200 dark:bg-slate-600 sm:block" aria-hidden />
            <button
              type="button"
              onClick={openCreateCategory}
              className="inline-flex items-center gap-2 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-emerald-700 hover:shadow dark:shadow-emerald-900/30 disabled:opacity-60"
              disabled={loading || saving}
            >
              <Plus className="h-4 w-4" />
              Ajouter categorie
            </button>
          </div>
        </div>

        {hasFilters ? (
          <div className="mt-3 text-xs text-gray-500 dark:text-slate-400">
            Affichage: {visibleCategories.length} categories / {visibleItemsCount} plats (sur{' '}
            {menuStats.totalCategories} / {menuStats.totalItems})
          </div>
        ) : null}
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-4 dark:bg-slate-900 dark:border-slate-700">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <Printer className="h-5 w-5 text-slate-600 dark:text-slate-400" />
            <h2 className="text-lg font-semibold text-gray-900 dark:text-slate-100">
              Imprimantes
            </h2>
          </div>
          <button
            type="button"
            onClick={openPrinterCreate}
            disabled={printerSaving}
            className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white transition-colors hover:bg-emerald-700 disabled:opacity-60"
          >
            <Plus className="h-4 w-4" />
            Ajouter
          </button>
        </div>
        <p className="mt-2 text-sm text-gray-600 dark:text-slate-300">
          Liste des imprimantes configurees pour ce restaurant. Vous pouvez modifier ou supprimer.
        </p>

        {printerError ? (
          <div className="mt-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
            {printerError}
          </div>
        ) : null}

        {printersLoading ? (
          <div className="mt-4 text-sm text-gray-500 dark:text-slate-300">Chargement...</div>
        ) : printers.length === 0 ? (
          <div className="mt-4 rounded-lg border border-dashed border-gray-300 bg-gray-50/60 py-6 text-center text-sm text-gray-500 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-400">
            Aucune imprimante configuree.
          </div>
        ) : (
          <div className="mt-4 space-y-3">
            {printers.map((printer) => (
              <div
                key={printer.id}
                className="flex flex-wrap items-center justify-between gap-3 rounded-lg border border-gray-200 bg-gray-50/50 p-3 dark:border-slate-700 dark:bg-slate-950"
              >
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-medium text-gray-900 dark:text-slate-100">
                      {printer.name}
                    </span>
                    <span className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${getPrinterTypeBadge(printer.type)}`}>
                      {getPrinterTypeLabel(printer.type)}
                    </span>
                    {!printer.is_enabled && (
                      <span className="rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-medium text-amber-800 dark:bg-amber-900/30 dark:text-amber-200">
                        Desactivee
                      </span>
                    )}
                  </div>
                  <div className="mt-1 text-sm text-gray-600 dark:text-slate-300">
                    {isWindowsPrinterIp(printer.ip) ? (
                      <>
                        <span className="font-medium">Windows:</span>{' '}
                        {getWindowsPrinterDisplayName(printer.ip)}
                        <span className="ml-2 text-xs text-amber-600 dark:text-amber-400">
                          (Backend sur meme PC requis)
                        </span>
                      </>
                    ) : isLocalPrinterIp(printer.ip) ? (
                      <>
                        <span className="font-medium">{printer.ip}</span> (locale)
                        <span className="ml-2 text-xs text-amber-600 dark:text-amber-400">
                          (Backend sur meme PC requis)
                        </span>
                      </>
                    ) : (
                      <>
                        <span className="font-medium">
                          {printer.ip}:{printer.port}
                        </span>{' '}
                        (reseau)
                        <span className="ml-2 text-xs text-blue-600 dark:text-blue-400">
                          (Meme reseau requis)
                        </span>
                      </>
                    )}
                    {' * '}
                    {printer.paper_width_mm} mm
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => openPrinterEdit(printer)}
                    disabled={printerSaving}
                    className="rounded-lg border border-gray-200 px-3 py-1.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 disabled:opacity-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    title="Modifier"
                  >
                    <Edit className="h-4 w-4" />
                  </button>
                  <button
                    type="button"
                    onClick={() => handlePrinterDelete(printer)}
                    disabled={printerSaving}
                    className="rounded-lg border border-red-200 px-3 py-1.5 text-sm font-medium text-red-700 transition-colors hover:bg-red-50 disabled:opacity-50 dark:border-red-800 dark:text-red-200 dark:hover:bg-red-900/20"
                    title="Supprimer"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="space-y-4">
        {loading ? (
          <div className="text-sm text-gray-500 dark:text-slate-300">Chargement...</div>
        ) : sortedCategories.length === 0 ? (
          <div className="rounded-xl border border-dashed border-gray-300 bg-white p-6 text-sm text-gray-600 dark:bg-slate-900 dark:border-slate-700 dark:text-slate-300">
            Aucune categorie de menu pour ce restaurant.
          </div>
        ) : visibleCategories.length === 0 ? (
          <div className="rounded-xl border border-dashed border-gray-300 bg-white p-6 text-sm text-gray-600 dark:bg-slate-900 dark:border-slate-700 dark:text-slate-300">
            Aucun resultat pour ces filtres.
          </div>
        ) : (
          visibleCategories.map((category) => {
            const items = category.items || [];
            return (
              <div
                key={category.id}
                className="rounded-xl border border-gray-200 bg-white dark:bg-slate-900 dark:border-slate-700"
              >
                <div className="flex flex-col gap-3 border-b border-gray-100 p-4 dark:border-slate-800 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <div className="text-base font-semibold text-gray-900 dark:text-slate-100">
                      {category.nom}
                    </div>
                    {category.description ? (
                      <div className="mt-1 text-sm text-gray-600 dark:text-slate-300">
                        {category.description}
                      </div>
                    ) : null}
                    <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-500 dark:text-slate-400">
                      <span>{items.length} plats</span>
                      {category.ordre_affichage != null ? (
                        <span>Ordre: {category.ordre_affichage}</span>
                      ) : null}
                      {category.icone_url ? (
                        <a
                          href={category.icone_url}
                          target="_blank"
                          rel="noreferrer"
                          className="text-indigo-600 hover:underline dark:text-indigo-300"
                        >
                          Icone
                        </a>
                      ) : null}
                      <span className="font-mono">ID: {category.id}</span>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-2">
                    <button
                      type="button"
                      onClick={() => openCreateItem(category.id)}
                      className="inline-flex items-center gap-2 rounded-xl bg-indigo-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-indigo-700 disabled:opacity-60 dark:bg-indigo-500 dark:hover:bg-indigo-600"
                      disabled={saving}
                    >
                      <Plus className="h-4 w-4" />
                      Ajouter plat
                    </button>
                    <button
                      type="button"
                      onClick={() => openEditCategory(category)}
                      className="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 hover:border-slate-300 disabled:opacity-60 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-800"
                      disabled={saving}
                      title="Modifier la categorie"
                    >
                      <Edit className="h-4 w-4" />
                      Modifier
                    </button>
                    <button
                      type="button"
                      onClick={() => openDeleteCategory(category)}
                      className="inline-flex items-center gap-2 rounded-xl border border-red-200 px-3 py-2 text-sm font-medium text-red-600 transition hover:bg-red-50 hover:border-red-300 disabled:opacity-60 dark:border-red-800 dark:text-red-300 dark:hover:bg-red-900/20"
                      disabled={saving}
                      title="Supprimer la categorie"
                    >
                      <Trash2 className="h-4 w-4" />
                      Supprimer
                    </button>
                  </div>
                </div>

              

                <div className="p-4">
                  {items.length === 0 ? (
                    <div className="text-sm text-gray-500 dark:text-slate-300">
                      Aucun plat dans cette categorie.
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {items.map((item) => (
                        <div
                          key={item.id}
                          className="rounded-lg border border-gray-200 p-3 dark:border-slate-700"
                        >
                          <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                            <div className="flex min-w-0 items-start gap-3">
                              {item.photo_url ? (
                                <img
                                  src={item.photo_url}
                                  alt={item.nom}
                                  className="h-16 w-16 flex-none rounded-lg object-cover"
                                />
                              ) : (
                                <div className="h-16 w-16 flex-none rounded-lg bg-gray-100 dark:bg-slate-800" />
                              )}

                              <div className="min-w-0">
                                <div className="flex flex-wrap items-center gap-2">
                                  <div className="truncate font-semibold text-gray-900 dark:text-slate-100">
                                    {item.nom}
                                  </div>
                                  <span
                                    className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                                      item.is_available
                                        ? 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-200'
                                        : 'bg-gray-100 text-gray-700 dark:bg-slate-800 dark:text-slate-300'
                                    }`}
                                  >
                                    {item.is_available ? 'Disponible' : 'Indisponible'}
                                  </span>
                                  {item.promotions?.length
                                    ? item.promotions.map((promo) => (
                                        <span
                                          key={promo.id}
                                          className="rounded-full bg-amber-100 px-2 py-0.5 text-xs font-medium text-amber-800 dark:bg-amber-900/30 dark:text-amber-200"
                                          title={promo.title}
                                        >
                                          {promo.badge_text || promo.title}
                                        </span>
                                      ))
                                    : null}
                                </div>

                                {item.description ? (
                                  <div className="mt-1 text-sm text-gray-600 dark:text-slate-300">
                                    {item.description}
                                  </div>
                                ) : null}

                                <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-sm text-gray-700 dark:text-slate-200">
                                  <span>Prix: {formatDA(item.display_price ?? item.prix)}</span>
                                  {item.temps_preparation != null ? (
                                    <span>Preparation: {item.temps_preparation} min</span>
                                  ) : null}
                                  <span className="text-xs text-gray-500 dark:text-slate-400 font-mono">
                                    ID: {item.id}
                                  </span>
                                </div>

                                {item.photo_url ? (
                                  <a
                                    href={item.photo_url}
                                    target="_blank"
                                    rel="noreferrer"
                                    className="mt-1 inline-block text-xs text-indigo-600 hover:underline dark:text-indigo-300"
                                  >
                                    Ouvrir la photo
                                  </a>
                                ) : null}
                              </div>
                            </div>

                            <div className="flex flex-wrap items-center gap-2">
                              <button
                                type="button"
                                onClick={() => onToggleAvailability(item.id)}
                                className={`inline-flex items-center gap-2 rounded-xl border px-3 py-2 text-sm font-medium transition disabled:opacity-60 ${
                                  item.is_available
                                    ? 'border-amber-200 text-amber-700 hover:bg-amber-50 dark:border-amber-800 dark:text-amber-200 dark:hover:bg-amber-900/20'
                                    : 'border-emerald-200 text-emerald-700 hover:bg-emerald-50 dark:border-emerald-800 dark:text-emerald-200 dark:hover:bg-emerald-900/20'
                                }`}
                                disabled={saving}
                                title={item.is_available ? 'Masquer du menu' : 'Rendre visible'}
                              >
                                {item.is_available ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                                {item.is_available ? 'Desactiver' : 'Activer'}
                              </button>
                              <button
                                type="button"
                                onClick={() => openOptionGroupModal(item, 'create')}
                                className="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 hover:border-slate-300 disabled:opacity-60 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-800"
                                disabled={saving}
                                title="Groupes d'options (tailles, cuisson...)"
                              >
                                <Layers className="h-4 w-4" />
                                Groupe
                              </button>
                              <button
                                type="button"
                                onClick={() => openAdditionModal(item, 'create')}
                                className="inline-flex items-center gap-2 rounded-xl border border-violet-200 px-3 py-2 text-sm font-medium text-violet-700 transition hover:bg-violet-50 hover:border-violet-300 disabled:opacity-60 dark:border-violet-800 dark:text-violet-200 dark:hover:bg-violet-900/20"
                                disabled={saving}
                                title="Additions (supplements)"
                              >
                                <CirclePlus className="h-4 w-4" />
                                Addition
                              </button>
                              <button
                                type="button"
                                onClick={() => openPromotionModal(item)}
                                className="inline-flex items-center gap-2 rounded-xl border border-amber-200 px-3 py-2 text-sm font-medium text-amber-700 transition hover:bg-amber-50 hover:border-amber-300 disabled:opacity-60 dark:border-amber-800 dark:text-amber-200 dark:hover:bg-amber-900/20"
                                disabled={saving}
                                title="Promotions appliquees"
                              >
                                <Zap className="h-4 w-4" />
                                Promos
                              </button>
                              <span className="hidden h-6 w-px bg-slate-200 dark:bg-slate-600 sm:block" aria-hidden />
                              <button
                                type="button"
                                onClick={() => openEditItem(item, category.id)}
                                className="inline-flex items-center gap-2 rounded-xl border border-slate-200 px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 hover:border-slate-300 disabled:opacity-60 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-800"
                                disabled={saving}
                                title="Modifier le plat"
                              >
                                <Edit className="h-4 w-4" />
                                Modifier
                              </button>
                              <button
                                type="button"
                                onClick={() => openDeleteItem(item)}
                                className="inline-flex items-center gap-2 rounded-xl border border-red-200 px-3 py-2 text-sm font-medium text-red-600 transition hover:bg-red-50 hover:border-red-300 disabled:opacity-60 dark:border-red-800 dark:text-red-300 dark:hover:bg-red-900/20"
                                disabled={saving}
                                title="Supprimer le plat"
                              >
                                <Trash2 className="h-4 w-4" />
                                Supprimer
                              </button>
                            </div>
                          </div>

                          <details className="mt-3 rounded-lg border border-dashed border-gray-200 bg-gray-50/80 dark:border-slate-700 dark:bg-slate-900/50">
                            <summary className="cursor-pointer px-3 py-2 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-slate-400">
                              Groupes d&apos;options ({item.option_groups?.length ?? 0})
                            </summary>
                            <div className="px-3 pb-3">
                              {item.option_groups && item.option_groups.length > 0 ? (
                                <div className="mt-3 space-y-2 text-sm text-gray-700 dark:text-slate-100">
                                  {item.option_groups.map((group) => {
                                    const groupOptions = resolveGroupOptions(item, group);
                                    return (
                                      <div
                                        key={group.id}
                                        className="rounded-lg border border-gray-200 bg-white p-2 text-xs shadow-sm dark:border-slate-700 dark:bg-slate-800"
                                      >
                                        <div className="flex flex-wrap items-center justify-between gap-2 text-sm font-medium text-gray-900 dark:text-slate-100">
                                          <div className="flex items-center gap-2">
                                            <span className="truncate">{group.nom}</span>
                                            <span
                                              className={`rounded-full px-2 py-0.5 text-[10px] font-semibold ${
                                                group.is_required
                                                  ? 'bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-200'
                                                  : 'bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-300'
                                              }`}
                                            >
                                              {group.is_required ? 'Obligatoire' : 'Optionnel'}
                                            </span>
                                          </div>
                                          <span className="text-xs text-slate-500 dark:text-slate-400">
                                            {groupOptions.length} option(s)
                                          </span>
                                        </div>
                                        {group.description ? (
                                          <div className="mt-1 text-xs text-gray-500 dark:text-slate-400">
                                            {group.description}
                                          </div>
                                        ) : null}
                                        {groupOptions.length > 0 ? (
                                          <div className="mt-2 flex flex-wrap gap-2 text-xs text-gray-600 dark:text-slate-300">
                                            {groupOptions.map((option) => (
                                              <span
                                                key={option.id}
                                                className="rounded-full border border-gray-200 bg-gray-50 px-2 py-0.5 dark:border-slate-700 dark:bg-slate-900"
                                              >
                                                {option.nom} ({formatDA(option.prix)})
                                              </span>
                                            ))}
                                          </div>
                                        ) : (
                                          <div className="mt-2 text-xs italic text-gray-500 dark:text-slate-400">
                                            Aucune option dans ce groupe.
                                          </div>
                                        )}
                                        <div className="mt-3 flex flex-wrap items-center gap-2 border-t border-slate-100 pt-2 dark:border-slate-700">
                                          <button
                                            type="button"
                                            onClick={() => openOptionGroupModal(item, 'edit', group)}
                                            className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-2.5 py-1.5 text-xs font-medium text-slate-700 transition hover:bg-slate-50 hover:border-slate-300 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
                                            title="Modifier le groupe et ses options"
                                          >
                                            <Edit className="h-4 w-4 shrink-0" />
                                            Modifier
                                          </button>
                                          <button
                                            type="button"
                                            onClick={() => handleDeleteOptionGroup(item.id, group.id)}
                                            className="inline-flex items-center gap-1.5 rounded-lg border border-red-200 px-2.5 py-1.5 text-xs font-medium text-red-600 transition hover:bg-red-50 hover:border-red-300 dark:border-red-800 dark:text-red-300 dark:hover:bg-red-900/20"
                                            title="Supprimer ce groupe d'options"
                                          >
                                            <Trash2 className="h-4 w-4 shrink-0" />
                                            Supprimer
                                          </button>
                                        </div>
                                      </div>
                                    );
                                  })}
                                </div>
                              ) : (
                                <div className="mt-3 text-xs italic text-gray-500 dark:text-slate-400">
                                  Aucun groupe pour ce plat.
                                </div>
                              )}
                            </div>
                          </details>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            );
          })
        )}
      </div>

      {modal ? (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-2xl rounded-xl bg-white shadow-xl dark:bg-slate-900">
            <div className="flex items-center justify-between border-b border-gray-100 px-4 py-3 dark:border-slate-800">
              <div className="font-semibold text-gray-900 dark:text-slate-100">
                {modal === 'create-category'
                  ? 'Creer une categorie'
                  : modal === 'edit-category'
                  ? 'Modifier la categorie'
                  : modal === 'delete-category'
                  ? 'Supprimer la categorie'
                  : modal === 'create-item'
                  ? 'Creer un plat'
                  : modal === 'edit-item'
                  ? 'Modifier le plat'
                  : 'Supprimer le plat'}
              </div>
              <button
                type="button"
                onClick={closeModal}
                className="rounded-lg p-2 hover:bg-gray-50 dark:hover:bg-slate-800"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            <div className="p-4">
              {modalError ? (
                <div className="mb-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-200">
                  {modalError}
                </div>
              ) : null}

              {modal === 'create-category' || modal === 'edit-category' ? (
                <div className="space-y-3">
                  <div>
                    <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                      Nom
                    </label>
                    <input
                      value={categoryForm.nom}
                      onChange={(e) => setCategoryForm((p) => ({ ...p, nom: e.target.value }))}
                      className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                      placeholder="Ex: Tacos"
                    />
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                      Description
                    </label>
                    <textarea
                      value={categoryForm.description}
                      onChange={(e) =>
                        setCategoryForm((p) => ({ ...p, description: e.target.value }))
                      }
                      className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                      rows={3}
                      placeholder="Optionnel"
                    />
                  </div>

                  <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                    <div>
                      <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                        Icone URL
                      </label>
                      <input
                        value={categoryForm.icone_url}
                        onChange={(e) => {
                          setCategoryForm((p) => ({ ...p, icone_url: e.target.value }));
                          setCategoryImagePreview(null);
                        }}
                        className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        placeholder="https://..."
                      />
                    </div>

                    <div>
                      <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                        Ordre d&apos;affichage
                      </label>
                      <input
                        value={categoryForm.ordre_affichage}
                        onChange={(e) =>
                          setCategoryForm((p) => ({ ...p, ordre_affichage: e.target.value }))
                        }
                        className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        placeholder="0"
                        inputMode="numeric"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                      Upload icone
                    </label>
                    <div className="mt-2 rounded-lg border border-dashed border-gray-200 p-3 dark:border-slate-700">
                      {categoryImagePreview || categoryForm.icone_url ? (
                        <div className="relative overflow-hidden rounded-lg border border-gray-200 bg-gray-50 dark:border-slate-700 dark:bg-slate-900">
                          <img
                            src={categoryImagePreview || categoryForm.icone_url}
                            alt="Apercu icone"
                            className="h-40 w-full object-cover"
                          />
                          <button
                            type="button"
                            onClick={removeCategoryImage}
                            className="absolute right-2 top-2 rounded-full bg-red-600 px-2 py-1 text-xs font-semibold text-white hover:bg-red-700"
                          >
                            Retirer
                          </button>
                        </div>
                      ) : (
                        <p className="text-sm text-gray-500 dark:text-slate-400">
                          Aucune image selectionnee.
                        </p>
                      )}

                      <div className="mt-3 flex flex-wrap items-center gap-2">
                        <label
                          htmlFor="category-icon-upload"
                          className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-gray-200 px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        >
                          {categoryImageUploading ? 'Upload en cours...' : 'Telecharger une image'}
                        </label>
                        <input
                          id="category-icon-upload"
                          type="file"
                          accept="image/*"
                          onChange={handleCategoryImageUpload}
                          disabled={categoryImageUploading}
                          className="hidden"
                        />
                        <span className="text-xs text-gray-500 dark:text-slate-400">
                          Formats image, max 5 MB
                        </span>
                      </div>

                      {categoryImageError ? (
                        <p className="mt-2 text-xs text-red-600">{categoryImageError}</p>
                      ) : null}
                    </div>
                  </div>
                </div>
              ) : null}

              {modal === 'create-item' || modal === 'edit-item' ? (
                <div className="space-y-3">
                  <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                    <div>
                      <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                        Categorie
                      </label>
                      <select
                        value={itemForm.category_id}
                        onChange={(e) => setItemForm((p) => ({ ...p, category_id: e.target.value }))}
                        className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                      >
                        <option value="">Choisir...</option>
                        {sortedCategories.map((c) => (
                          <option key={c.id} value={c.id}>
                            {c.nom}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                        Prix (DA)
                      </label>
                      <input
                        value={itemForm.prix}
                        onChange={(e) => setItemForm((p) => ({ ...p, prix: e.target.value }))}
                        className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        placeholder="1200"
                        inputMode="numeric"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                      Nom
                    </label>
                    <input
                      value={itemForm.nom}
                      onChange={(e) => setItemForm((p) => ({ ...p, nom: e.target.value }))}
                      className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                      placeholder="Ex: Tacos mixte"
                    />
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                      Description
                    </label>
                    <textarea
                      value={itemForm.description}
                      onChange={(e) =>
                        setItemForm((p) => ({ ...p, description: e.target.value }))
                      }
                      className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                      rows={3}
                      placeholder="Optionnel"
                    />
                  </div>

                  <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                    <div>
                      <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                        Photo URL
                      </label>
                      <input
                        value={itemForm.photo_url}
                        onChange={(e) => {
                          setItemForm((p) => ({ ...p, photo_url: e.target.value }));
                          setItemImagePreview(null);
                        }}
                        className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        placeholder="https://..."
                      />
                    </div>
                    <div>
                      <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                        Temps preparation (min)
                      </label>
                      <input
                        value={itemForm.temps_preparation}
                        onChange={(e) =>
                          setItemForm((p) => ({ ...p, temps_preparation: e.target.value }))
                        }
                        className="mt-1 w-full rounded-lg border border-gray-200 px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950 dark:text-slate-100"
                        placeholder="10"
                        inputMode="numeric"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="text-sm font-medium text-gray-700 dark:text-slate-200">
                      Upload photo
                    </label>
                    <div className="mt-2 rounded-lg border border-dashed border-gray-200 p-3 dark:border-slate-700">
                      {itemImagePreview || itemForm.photo_url ? (
                        <div className="relative overflow-hidden rounded-lg border border-gray-200 bg-gray-50 dark:border-slate-700 dark:bg-slate-900">
                          <img
                            src={itemImagePreview || itemForm.photo_url}
                            alt="Apercu plat"
                            className="h-40 w-full object-cover"
                          />
                          <button
                            type="button"
                            onClick={removeItemImage}
                            className="absolute right-2 top-2 rounded-full bg-red-600 px-2 py-1 text-xs font-semibold text-white hover:bg-red-700"
                          >
                            Retirer
                          </button>
                        </div>
                      ) : (
                        <p className="text-sm text-gray-500 dark:text-slate-400">
                          Aucune image selectionnee.
                        </p>
                      )}

                      <div className="mt-3 flex flex-wrap items-center gap-2">
                        <label
                          htmlFor="item-photo-upload"
                          className="inline-flex cursor-pointer items-center gap-2 rounded-lg border border-gray-200 px-3 py-2 text-xs font-medium text-gray-700 hover:bg-gray-50 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        >
                          {itemImageUploading ? 'Upload en cours...' : 'Telecharger une image'}
                        </label>
                        <input
                          id="item-photo-upload"
                          type="file"
                          accept="image/*"
                          onChange={handleItemImageUpload}
                          disabled={itemImageUploading}
                          className="hidden"
                        />
                        <span className="text-xs text-gray-500 dark:text-slate-400">
                          Formats image, max 5 MB
                        </span>
                      </div>

                      {itemImageError ? (
                        <p className="mt-2 text-xs text-red-600">{itemImageError}</p>
                      ) : null}
                    </div>
                  </div>

                  <label className="flex items-center gap-2 text-sm text-gray-700 dark:text-slate-200">
                    <input
                      type="checkbox"
                      checked={itemForm.is_available}
                      onChange={(e) => setItemForm((p) => ({ ...p, is_available: e.target.checked }))}
                    />
                    Disponible
                  </label>
                </div>
              ) : null}

              {modal === 'delete-category' ? (
                <div className="text-sm text-gray-700 dark:text-slate-200">
                  Supprimer la categorie <span className="font-semibold">{selectedCategory?.nom}</span> ?
                  <div className="mt-1 text-xs text-gray-500 dark:text-slate-400">
                    Si elle contient des plats, il faudra d&apos;abord les supprimer/deplacer.
                  </div>
                </div>
              ) : null}

              {modal === 'delete-item' ? (
                <div className="text-sm text-gray-700 dark:text-slate-200">
                  Supprimer le plat <span className="font-semibold">{selectedItem?.nom}</span> ?
                </div>
              ) : null}
            </div>

            <div className="flex flex-wrap items-center justify-end gap-2 border-t border-gray-100 px-4 py-3 dark:border-slate-800">
              <button
                type="button"
                onClick={closeModal}
                className="rounded-lg border border-gray-200 px-3 py-2 text-sm font-medium text-gray-900 hover:bg-gray-50 dark:border-slate-700 dark:text-slate-100 dark:hover:bg-slate-800"
                disabled={saving}
              >
                Annuler
              </button>

              {modal === 'create-category' ? (
                <button
                  type="button"
                  onClick={onCreateCategory}
                  className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60"
                  disabled={saving}
                >
                  <Save className="h-4 w-4" />
                  Creer
                </button>
              ) : null}

              {modal === 'edit-category' ? (
                <button
                  type="button"
                  onClick={onUpdateCategory}
                  className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60"
                  disabled={saving}
                >
                  <Save className="h-4 w-4" />
                  Enregistrer
                </button>
              ) : null}

              {modal === 'delete-category' ? (
                <button
                  type="button"
                  onClick={onDeleteCategory}
                  className="inline-flex items-center gap-2 rounded-lg bg-red-600 px-3 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60"
                  disabled={saving}
                >
                  <Trash2 className="h-4 w-4" />
                  Supprimer
                </button>
              ) : null}

              {modal === 'create-item' ? (
                <button
                  type="button"
                  onClick={onCreateItem}
                  className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60"
                  disabled={saving}
                >
                  <Save className="h-4 w-4" />
                  Creer
                </button>
              ) : null}

              {modal === 'edit-item' ? (
                <button
                  type="button"
                  onClick={onUpdateItem}
                  className="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-60"
                  disabled={saving}
                >
                  <Save className="h-4 w-4" />
                  Enregistrer
                </button>
              ) : null}

              {modal === 'delete-item' ? (
                <button
                  type="button"
                  onClick={onDeleteItem}
                  className="inline-flex items-center gap-2 rounded-lg bg-red-600 px-3 py-2 text-sm font-medium text-white hover:bg-red-700 disabled:opacity-60"
                  disabled={saving}
                >
                  <Trash2 className="h-4 w-4" />
                  Supprimer
                </button>
              ) : null}
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
