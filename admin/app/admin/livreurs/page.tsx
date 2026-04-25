'use client';

import { useState, useEffect } from 'react';
import {
  Search,
  Edit,
  Trash2,
  Eye,
  UserCheck,
  UserX,
  Mail,
  Phone,
  Calendar,
  AlertCircle,
  Car,
  Star,
  TrendingUp,
  MapPin,
  Activity,
  Award,
  Plus,
  X,
  Save,
  ChevronLeft,
  ChevronRight
} from 'lucide-react';
import { LOCALE_OPTIONS, normalizeLocale } from '@/lib/locale';
import ModalErrorNotice from '@/components/admin/ModalErrorNotice';
import { getApiErrorMessage } from '@/lib/api/error';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

// ==== TYPES ====

type DriverStatus = 'available' | 'busy' | 'offline' | 'suspended' | string;
type VehicleType = 'motorcycle' | 'bicycle' | 'scooter' | string;
const REJECTION_NOTE_PATTERN = /rejet[eé]\s*:/i;

interface Driver {
  id: string;
  user_id: string;
  driver_code: string;
  first_name: string;
  last_name: string;
  phone: string;
  email?: string | null;
  vehicle_type: VehicleType;
  vehicle_plate?: string | null;
  license_number?: string | null;
  status: DriverStatus;
  current_location?: any;
  rating?: number | null;
  total_deliveries: number;
  active_orders: string[];
  max_orders_capacity: number;
  is_verified: boolean;
  is_active: boolean;
  last_active_at?: string | null;
  notes?: string | null;
  cancellation_count: number;
  created_at: string;
  updated_at: string;
  profile_image_url:string;
  locale?: string | null;
  email_verified_at?: string | null;
}

interface DriverWarning {
  driver_id: string;
  driver?: Pick<
    Driver,
    | 'id'
    | 'driver_code'
    | 'first_name'
    | 'last_name'
    | 'phone'
    | 'status'
    | 'is_active'
    | 'cancellation_count'
  >;
  warnings_total: number;
  warnings_delay: number;
  warnings_cancellations: number;
  warnings_unresolved?: number;
  last_warning_at?: string | null;
}

type ModalType = '' | 'view' | 'edit' | 'delete' | 'create';
type ActiveTab =
  | 'all'
  | 'suspended'
  | 'rejected'
  | 'requests'
  | 'email-unconfirmed'
  | 'warnings';

interface CreateDriverForm {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  phone: string;
  vehicle_type: VehicleType;
  vehicle_plate: string;
  license_number: string;
  is_verified: boolean;
  is_active: boolean;
  profile_image_url?: string;
  locale: string;
}

interface EditDriverForm {
  first_name: string;
  last_name: string;
  email: string;
  password?: string;
  phone: string;
  vehicle_type: VehicleType;
  vehicle_plate: string;
  license_number: string;
  is_verified: boolean;
  is_active: boolean;
  status: DriverStatus;
  notes: string;
  profile_image_url?: string;
  locale: string;
  location_latitude: string;
  location_longitude: string;
}

const getCoordinatesFromPoint = (
  location: any
): { latitude: number; longitude: number } | null => {
  const coordinates = location?.coordinates;
  if (Array.isArray(coordinates) && coordinates.length === 2) {
    const longitude = Number(coordinates[0]);
    const latitude = Number(coordinates[1]);
    if (Number.isFinite(longitude) && Number.isFinite(latitude)) {
      return { latitude, longitude };
    }
  }

  const longitude = location?.longitude ?? location?.lng;
  const latitude = location?.latitude ?? location?.lat;
  if (longitude !== undefined && latitude !== undefined) {
    const parsedLongitude = Number(longitude);
    const parsedLatitude = Number(latitude);
    if (Number.isFinite(parsedLongitude) && Number.isFinite(parsedLatitude)) {
      return { latitude: parsedLatitude, longitude: parsedLongitude };
    }
  }

  return null;
};

const hasVerifiedEmail = (emailVerifiedAt?: string | null) =>
  Boolean(emailVerifiedAt && String(emailVerifiedAt).trim());

const filterPendingDriversWithVerifiedEmail = (drivers: Driver[]) =>
  drivers.filter(
    (driver) => driver.status !== 'suspended' && hasVerifiedEmail(driver.email_verified_at)
  );

const filterPendingDriversWithoutVerifiedEmail = (drivers: Driver[]) =>
  drivers.filter(
    (driver) => driver.status !== 'suspended' && !hasVerifiedEmail(driver.email_verified_at)
  );

export default function DriverManagement() {
  const [activeTab, setActiveTab] = useState<ActiveTab>('all');
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [suspendedDrivers, setSuspendedDrivers] = useState<Driver[]>([]);
  const [filteredSuspendedDrivers, setFilteredSuspendedDrivers] = useState<Driver[]>([]);
  const [rejectedDrivers, setRejectedDrivers] = useState<Driver[]>([]);
  const [filteredRejectedDrivers, setFilteredRejectedDrivers] = useState<Driver[]>([]);
  const [pendingDrivers, setPendingDrivers] = useState<Driver[]>([]);
  const [filteredPendingDrivers, setFilteredPendingDrivers] = useState<Driver[]>([]);
  const [pendingUnconfirmedEmailDrivers, setPendingUnconfirmedEmailDrivers] = useState<Driver[]>(
    []
  );
  const [filteredPendingUnconfirmedEmailDrivers, setFilteredPendingUnconfirmedEmailDrivers] =
    useState<Driver[]>([]);
  const [warningDrivers, setWarningDrivers] = useState<DriverWarning[]>([]);
  const [filteredWarningDrivers, setFilteredWarningDrivers] = useState<DriverWarning[]>([]);
  const [warningSearchTerm, setWarningSearchTerm] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [filterStatus, setFilterStatus] = useState<
    'all' | 'available' | 'busy' | 'offline' | 'verified' | 'unverified'
  >('all');
  const [pendingSearchTerm, setPendingSearchTerm] = useState<string>('');
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  const [showModal, setShowModal] = useState<boolean>(false);
  const [modalType, setModalType] = useState<ModalType>('');
  const [editFormData, setEditFormData] = useState<Partial<EditDriverForm>>({});
  const [saveLoading, setSaveLoading] = useState<boolean>(false);

  // Validation states
  const [createFormErrors, setCreateFormErrors] = useState<Record<string, string>>({});
  const [editFormErrors, setEditFormErrors] = useState<Record<string, string>>({});

  // Pagination states
  const [currentPage, setCurrentPage] = useState<number>(1);
  const [pageSize, setPageSize] = useState<number>(20);
  const [totalPages, setTotalPages] = useState<number>(1);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [totalDriversCount, setTotalDriversCount] = useState<number>(0);

  // Image upload states
  const [uploadingImage, setUploadingImage] = useState<boolean>(false);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [editUploadingImage, setEditUploadingImage] = useState<boolean>(false);
  const [editImagePreview, setEditImagePreview] = useState<string | null>(null);
  const [updatingDriverIds, setUpdatingDriverIds] = useState<Record<string, boolean>>({});

  // Create form state
  const [createForm, setCreateForm] = useState<CreateDriverForm>({
    email: '',
    password: '',
    first_name: '',
    last_name: '',
    phone: '',
    vehicle_type: 'motorcycle',
    vehicle_plate: '',
    license_number: '',
    is_verified: false,
    is_active: true,
    profile_image_url: '',
    locale: 'fr'
  });

  useEffect(() => {
    if (activeTab !== 'all') return;
    fetchDrivers();
  }, [currentPage, pageSize, searchTerm, filterStatus, activeTab]);

  useEffect(() => {
    if (activeTab === 'requests' || activeTab === 'email-unconfirmed') {
      fetchPendingDrivers();
      fetchTotalDriversCount();
    } else if (activeTab === 'warnings') {
      fetchWarningDrivers();
    } else if (activeTab === 'suspended') {
      fetchSuspendedDrivers();
    } else if (activeTab === 'rejected') {
      fetchRejectedDrivers();
    }
  }, [activeTab]);

  useEffect(() => {
    applyPendingSearchFilter();
  }, [pendingDrivers, pendingSearchTerm]);

  useEffect(() => {
    applyPendingUnconfirmedSearchFilter();
  }, [pendingUnconfirmedEmailDrivers, pendingSearchTerm]);

  useEffect(() => {
    applyWarningSearchFilter();
  }, [warningDrivers, warningSearchTerm]);

  useEffect(() => {
    applySuspendedSearchFilter();
  }, [suspendedDrivers, searchTerm]);

  useEffect(() => {
    applyRejectedSearchFilter();
  }, [rejectedDrivers, searchTerm]);

  useEffect(() => {
    prefetchTabLists();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fetchDrivers = async () => {
    try {
      setLoading(true);
      setError('');

      const token = localStorage.getItem('access_token');
      if (!token) {
        setError('Non authentifie. Veuillez vous reconnecter.');
        setLoading(false);
        return;
      }

      // Construire les parametres de requete
      const params = new URLSearchParams({
        page: currentPage.toString(),
        limit: pageSize.toString()
      });

      // Ajouter la recherche si elle existe
      if (searchTerm.trim()) {
        params.append('search', searchTerm.trim());
      }

      // L'onglet "Tous les livreurs" ne doit pas inclure les demandes en attente.
      if (filterStatus === 'unverified') {
        params.append('is_verified', 'false');
      } else {
        params.append('is_verified', 'true');
        params.append('is_active', 'true');
      }

      // Ajouter les filtres de statut
      if (filterStatus === 'available') {
        params.append('status', 'available');
      } else if (filterStatus === 'busy') {
        params.append('status', 'busy');
      } else if (filterStatus === 'offline') {
        params.append('status', 'offline');
      }

      const response = await fetch(`${API_URL}/driver/getall?${params.toString()}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors du chargement des livreurs');
      }

      const data = await response.json();

      if (data.success && data.data) {
        const allDrivers = data.data as Driver[];
        setDrivers(allDrivers);
        
        // Mettre A  jour la pagination depuis le backend
        if (data.pagination) {
          setTotalCount(data.pagination.total_items || 0);
          setTotalPages(data.pagination.total_pages || 1);
          setTotalDriversCount(data.pagination.total_items || 0);
        }
        
      } else {
        throw new Error('Format de donnees invalide');
      }
    } catch (err: any) {
      console.error('Erreur fetch drivers:', err);
      setError(err?.message || 'Impossible de charger les livreurs');
    } finally {
      setLoading(false);
    }
  };

  // Recuperer toutes les demandes en attente (sans pagination)
  const fetchPendingDrivers = async (options: { silent?: boolean } = {}) => {
    const { silent = false } = options;
    try {
      if (!silent) {
        setLoading(true);
        setError('');
      }

      const token = localStorage.getItem('access_token');
      if (!token) {
        if (!silent) {
          setError('Non authentifie. Veuillez vous reconnecter.');
        }
        return;
      }

      // Recuperer tous les livreurs non verifies
      // Utiliser une limite elevee mais raisonnable (100) et recuperer toutes les pages si necessaire
      const params = new URLSearchParams({
        page: '1',
        limit: '100' // Limite maximale autorisee par le backend
      });
      // Ajouter is_verified comme booleen (le backend le convertit correctement)
      params.append('is_verified', 'false');

      const response = await fetch(`${API_URL}/driver/getall?${params.toString()}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Error response:', errorText);
        throw new Error(`Erreur lors du chargement des demandes: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();

      if (data.success && data.data) {
        const allPendingRaw = [...(data.data as Driver[])];
        
        // Si il y a plus de resultats, recuperer les pages suivantes
        if (data.pagination && data.pagination.total_pages > 1) {
          // Recuperer les pages restantes
          for (let page = 2; page <= data.pagination.total_pages; page++) {
            try {
              const pageParams = new URLSearchParams({
                page: page.toString(),
                limit: '100'
              });
              pageParams.append('is_verified', 'false');
              
              const pageResponse = await fetch(`${API_URL}/driver/getall?${pageParams.toString()}`, {
                headers: {
                  Authorization: `Bearer ${token}`,
                  'Content-Type': 'application/json'
                }
              });
              
              if (pageResponse.ok) {
                const pageData = await pageResponse.json();
                if (pageData.success && pageData.data) {
                  allPendingRaw.push(...(pageData.data as Driver[]));
                }
              }
            } catch (pageErr) {
              console.warn(`Erreur lors du chargement de la page ${page}:`, pageErr);
            }
          }
        }

        const pendingConfirmed = filterPendingDriversWithVerifiedEmail(allPendingRaw);
        const pendingUnconfirmed = filterPendingDriversWithoutVerifiedEmail(allPendingRaw);

        setPendingDrivers(pendingConfirmed);
        setFilteredPendingDrivers(pendingConfirmed);
        setPendingUnconfirmedEmailDrivers(pendingUnconfirmed);
        setFilteredPendingUnconfirmedEmailDrivers(pendingUnconfirmed);
      } else {
        throw new Error('Format de donnees invalide');
      }
    } catch (err: any) {
      console.error('Erreur fetch pending drivers:', err);
      if (!silent) {
        setError(err?.message || 'Impossible de charger les demandes');
      }
    } finally {
      if (!silent) {
        setLoading(false);
      }
    }
  };

  const isRejectedDriver = (driver: Driver) =>
    REJECTION_NOTE_PATTERN.test(driver.notes || '');

  const matchesDriverSearch = (driver: Driver, rawQuery: string) => {
    const query = rawQuery.toLowerCase();
    return (
      driver.first_name?.toLowerCase().includes(query) ||
      driver.last_name?.toLowerCase().includes(query) ||
      driver.email?.toLowerCase().includes(query) ||
      driver.phone?.toLowerCase().includes(query) ||
      driver.driver_code?.toLowerCase().includes(query) ||
      driver.license_number?.toLowerCase().includes(query)
    );
  };

  const fetchSuspendedDrivers = async (options: { silent?: boolean } = {}) => {
    const { silent = false } = options;
    try {
      if (!silent) {
        setLoading(true);
        setError('');
      }

      const token = localStorage.getItem('access_token');
      if (!token) {
        if (!silent) {
          setError('Non authentifie. Veuillez vous reconnecter.');
        }
        return;
      }

      const params = new URLSearchParams({
        page: '1',
        limit: '100',
        status: 'suspended',
        is_verified: 'true'
      });

      const response = await fetch(`${API_URL}/driver/getall?${params.toString()}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Error response:', errorText);
        throw new Error(`Erreur lors du chargement des livreurs suspendus: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();

      if (data.success && data.data) {
        const allSuspended = (data.data as Driver[]).filter((driver) => !isRejectedDriver(driver));
        setSuspendedDrivers(allSuspended);
        setFilteredSuspendedDrivers(allSuspended);

        if (data.pagination && data.pagination.total_pages > 1) {
          const allPages: Driver[] = [...allSuspended];

          for (let page = 2; page <= data.pagination.total_pages; page++) {
            try {
              const pageParams = new URLSearchParams({
                page: page.toString(),
                limit: '100',
                status: 'suspended',
                is_verified: 'true'
              });

              const pageResponse = await fetch(`${API_URL}/driver/getall?${pageParams.toString()}`, {
                headers: {
                  Authorization: `Bearer ${token}`,
                  'Content-Type': 'application/json'
                }
              });

              if (pageResponse.ok) {
                const pageData = await pageResponse.json();
                if (pageData.success && pageData.data) {
                  const pageDrivers = (pageData.data as Driver[]).filter((driver) => !isRejectedDriver(driver));
                  allPages.push(...pageDrivers);
                }
              }
            } catch (pageErr) {
              console.warn(`Erreur lors du chargement de la page ${page}:`, pageErr);
            }
          }

          setSuspendedDrivers(allPages);
          setFilteredSuspendedDrivers(allPages);
        }
      } else {
        throw new Error('Format de donnees invalide');
      }
    } catch (err: any) {
      console.error('Erreur fetch suspended drivers:', err);
      if (!silent) {
        setError(err?.message || 'Impossible de charger les livreurs suspendus');
      }
    } finally {
      if (!silent) {
        setLoading(false);
      }
    }
  };

  const fetchRejectedDrivers = async (options: { silent?: boolean } = {}) => {
    const { silent = false } = options;
    try {
      if (!silent) {
        setLoading(true);
        setError('');
      }

      const token = localStorage.getItem('access_token');
      if (!token) {
        if (!silent) {
          setError('Non authentifie. Veuillez vous reconnecter.');
        }
        return;
      }

      const params = new URLSearchParams({
        page: '1',
        limit: '100',
        status: 'suspended',
        is_verified: 'false'
      });

      const response = await fetch(`${API_URL}/driver/getall?${params.toString()}`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const errorText = await response.text();
        console.error('Error response:', errorText);
        throw new Error(`Erreur lors du chargement des livreurs rejetes: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();

      if (data.success && data.data) {
        const allRejected = (data.data as Driver[]).filter(isRejectedDriver);
        setRejectedDrivers(allRejected);
        setFilteredRejectedDrivers(allRejected);

        if (data.pagination && data.pagination.total_pages > 1) {
          const allPages: Driver[] = [...allRejected];

          for (let page = 2; page <= data.pagination.total_pages; page++) {
            try {
              const pageParams = new URLSearchParams({
                page: page.toString(),
                limit: '100',
                status: 'suspended',
                is_verified: 'false'
              });

              const pageResponse = await fetch(`${API_URL}/driver/getall?${pageParams.toString()}`, {
                headers: {
                  Authorization: `Bearer ${token}`,
                  'Content-Type': 'application/json'
                }
              });

              if (pageResponse.ok) {
                const pageData = await pageResponse.json();
                if (pageData.success && pageData.data) {
                  const pageDrivers = (pageData.data as Driver[]).filter(isRejectedDriver);
                  allPages.push(...pageDrivers);
                }
              }
            } catch (pageErr) {
              console.warn(`Erreur lors du chargement de la page ${page}:`, pageErr);
            }
          }

          setRejectedDrivers(allPages);
          setFilteredRejectedDrivers(allPages);
        }
      } else {
        throw new Error('Format de donnees invalide');
      }
    } catch (err: any) {
      console.error('Erreur fetch rejected drivers:', err);
      if (!silent) {
        setError(err?.message || 'Impossible de charger les livreurs rejetes');
      }
    } finally {
      if (!silent) {
        setLoading(false);
      }
    }
  };

  // Recuperer le nombre total de tous les livreurs
  
  const fetchWarningDrivers = async (options: { silent?: boolean } = {}) => {
    const { silent = false } = options;
    try {
      if (!silent) {
        setLoading(true);
        setError('');
      }

      const token = localStorage.getItem('access_token');
      if (!token) {
        if (!silent) {
          setError('Non authentifie. Veuillez vous reconnecter.');
        }
        return;
      }

      const response = await fetch(`${API_URL}/admin/warnings/drivers`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error('Erreur lors du chargement des avertissements');
      }

      const data = await response.json();
      if (data.success && data.data) {
        setWarningDrivers(data.data as DriverWarning[]);
        setFilteredWarningDrivers(data.data as DriverWarning[]);
      } else {
        throw new Error('Format de donnees invalide');
      }
    } catch (err: any) {
      console.error('Erreur fetch warning drivers:', err);
      if (!silent) {
        setError(err?.message || 'Impossible de charger les avertissements');
      }
    } finally {
      if (!silent) {
        setLoading(false);
      }
    }
  };

  const fetchTotalDriversCount = async () => {
    try {
      const token = localStorage.getItem('access_token');
      if (!token) return;

      // Recuperer juste le count total (premiere page avec limit 1)
      const response = await fetch(`${API_URL}/driver/getall?page=1&limit=1`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (response.ok) {
        const data = await response.json();
        if (data.success && data.pagination) {
          setTotalDriversCount(data.pagination.total_items || 0);
        }
      }
    } catch (err: any) {
      console.error('Erreur fetch total drivers count:', err);
    }
  };

  const prefetchTabLists = async () => {
    try {
      await Promise.all([
        fetchPendingDrivers({ silent: true }),
        fetchWarningDrivers({ silent: true }),
        fetchSuspendedDrivers({ silent: true }),
        fetchRejectedDrivers({ silent: true })
      ]);
    } catch (err) {
      console.warn('prefetchTabLists failed:', err);
    }
  };

  const handleRefresh = () => {
    refreshDriverData();
    prefetchTabLists();
  };

  // Reinitialiser A  la page 1 quand la recherche ou le filtre change
  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, filterStatus, activeTab]);

  const applyPendingSearchFilter = () => {
    let filtered = [...pendingDrivers];
    if (pendingSearchTerm.trim()) {
      filtered = filtered.filter((driver) => matchesDriverSearch(driver, pendingSearchTerm));
    }
    setFilteredPendingDrivers(filtered);
  };

  const applyPendingUnconfirmedSearchFilter = () => {
    let filtered = [...pendingUnconfirmedEmailDrivers];
    if (pendingSearchTerm.trim()) {
      filtered = filtered.filter((driver) => matchesDriverSearch(driver, pendingSearchTerm));
    }
    setFilteredPendingUnconfirmedEmailDrivers(filtered);
  };

  const applyWarningSearchFilter = () => {
    let filtered = [...warningDrivers];
    if (warningSearchTerm.trim()) {
      const query = warningSearchTerm.toLowerCase();
      filtered = filtered.filter((entry) => {
        const driver = entry.driver;
        return (
          driver?.first_name?.toLowerCase().includes(query) ||
          driver?.last_name?.toLowerCase().includes(query) ||
          driver?.driver_code?.toLowerCase().includes(query) ||
          driver?.phone?.toLowerCase().includes(query)
        );
      });
    }
    setFilteredWarningDrivers(filtered);
  };

  const applySuspendedSearchFilter = () => {
    let filtered = [...suspendedDrivers];
    if (searchTerm.trim()) {
      filtered = filtered.filter((driver) => matchesDriverSearch(driver, searchTerm));
    }
    setFilteredSuspendedDrivers(filtered);
  };

  const applyRejectedSearchFilter = () => {
    let filtered = [...rejectedDrivers];
    if (searchTerm.trim()) {
      filtered = filtered.filter((driver) => matchesDriverSearch(driver, searchTerm));
    }
    setFilteredRejectedDrivers(filtered);
  };

  const refreshDriverData = async () => {
    if (activeTab === 'all') {
      await fetchDrivers();
      return;
    }
    if (activeTab === 'warnings') {
      await fetchWarningDrivers();
      return;
    }
    if (activeTab === 'requests' || activeTab === 'email-unconfirmed') {
      await fetchPendingDrivers();
      await fetchTotalDriversCount();
      return;
    }
    if (activeTab === 'suspended') {
      await fetchSuspendedDrivers();
      return;
    }
    await fetchRejectedDrivers();
  };

  // Gerer les actions
  const handleAction = (driver: Driver, type: ModalType) => {
    setError('');
    setSelectedDriver(driver);

    if (type === 'edit') {
      const coords = getCoordinatesFromPoint(driver.current_location);
      setEditFormData({
        first_name: driver.first_name,
        last_name: driver.last_name,
        email: driver.email ?? '',
        password: '',
        phone: driver.phone,
        vehicle_type: driver.vehicle_type,
        vehicle_plate: driver.vehicle_plate ?? '',
        license_number: driver.license_number ?? '',
        is_verified: driver.is_verified,
        is_active: driver.is_active,
        status: driver.status,
        notes: driver.notes ?? '',
        profile_image_url: driver.profile_image_url ?? '',
        locale: normalizeLocale(driver.locale),
        location_latitude: coords ? String(coords.latitude) : '',
        location_longitude: coords ? String(coords.longitude) : ''
      });
      setEditImagePreview(driver.profile_image_url || null);
    }

    setModalType(type);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedDriver(null);
    setModalType('');
    setEditFormData({});
    setSaveLoading(false);
    setError('');
    setCreateFormErrors({});
    setEditFormErrors({});
    setImagePreview(null);
    setEditImagePreview(null);
    // Reset create form
    setCreateForm({
      email: '',
      password: '',
      first_name: '',
      last_name: '',
      phone: '',
      vehicle_type: 'motorcycle',
      vehicle_plate: '',
      license_number: '',
      is_verified: false,
      is_active: true,
      profile_image_url: '',
      locale: 'fr'
    });
  };

  // Validation functions
  const validateEmail = (email: string): string => {
    if (!email.trim()) return 'L\'email est obligatoire';
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) return 'Format d\'email invalide';
    return '';
  };

  const validatePassword = (password: string): string => {
    if (!password) return 'Le mot de passe est obligatoire';
    if (password.length < 6) return 'Le mot de passe doit contenir au moins 6 caracteres';
    return '';
  };

  const validateName = (name: string, fieldName: string): string => {
    if (!name.trim()) return `${fieldName} est obligatoire`;
    if (name.trim().length < 2) return `${fieldName} doit contenir au moins 2 caracteres`;
    return '';
  };

  const validatePhone = (phone: string): string => {
    if (!phone.trim()) return 'Le telephone est obligatoire';
    const phoneRegex = /^[\+]?[0-9\s\-\(\)]{8,}$/;
    if (!phoneRegex.test(phone.trim())) return 'Format de telephone invalide';
    return '';
  };

  const validateCreateForm = (): boolean => {
    const errors: Record<string, string> = {};

    errors.email = validateEmail(createForm.email);
    errors.password = validatePassword(createForm.password);
    errors.first_name = validateName(createForm.first_name, 'Le prenom');
    errors.last_name = validateName(createForm.last_name, 'Le nom');
    errors.phone = validatePhone(createForm.phone);
    if (!createForm.locale) {
      errors.locale = 'La langue est obligatoire';
    }

    // Remove empty errors
    Object.keys(errors).forEach(key => {
      if (!errors[key]) delete errors[key];
    });

    setCreateFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const validateEditForm = (): boolean => {
    const errors: Record<string, string> = {};

    if (editFormData.email !== undefined) {
      errors.email = validateEmail(editFormData.email);
    }
    if (editFormData.password !== undefined && editFormData.password.trim() !== '') {
      errors.password = validatePassword(editFormData.password);
    }
    if (editFormData.first_name !== undefined) {
      errors.first_name = validateName(editFormData.first_name, 'Le prenom');
    }
    if (editFormData.last_name !== undefined) {
      errors.last_name = validateName(editFormData.last_name, 'Le nom');
    }
    if (editFormData.phone !== undefined) {
      errors.phone = validatePhone(editFormData.phone);
    }
    if (editFormData.locale !== undefined && !editFormData.locale) {
      errors.locale = 'La langue est obligatoire';
    }

    const latitudeValue = (editFormData.location_latitude ?? '').trim();
    const longitudeValue = (editFormData.location_longitude ?? '').trim();
    const hasLatitude = latitudeValue.length > 0;
    const hasLongitude = longitudeValue.length > 0;

    if (hasLatitude || hasLongitude) {
      if (!hasLatitude) {
        errors.location_latitude = 'La latitude est obligatoire';
      }
      if (!hasLongitude) {
        errors.location_longitude = 'La longitude est obligatoire';
      }

      if (hasLatitude) {
        const latitude = Number.parseFloat(latitudeValue);
        if (!Number.isFinite(latitude) || latitude < -90 || latitude > 90) {
          errors.location_latitude = 'Latitude invalide (entre -90 et 90)';
        }
      }

      if (hasLongitude) {
        const longitude = Number.parseFloat(longitudeValue);
        if (!Number.isFinite(longitude) || longitude < -180 || longitude > 180) {
          errors.location_longitude = 'Longitude invalide (entre -180 et 180)';
        }
      }
    }

    // Remove empty errors
    Object.keys(errors).forEach(key => {
      if (!errors[key]) delete errors[key];
    });

    setEditFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleCreateDriver = async () => {
    // Validation
    if (!validateCreateForm()) {
      setError('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    try {
      setSaveLoading(true);
      setError('');
      setCreateFormErrors({});

      const response = await fetch(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          ...createForm,
          type: 'driver'
        })
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        const err: any = new Error(getApiErrorMessage(errorData, 'Erreur lors de la creation'));
        err.errors = errorData.errors;
        throw err;
      }

      const data = await response.json();

      if (data.success || data.access_token) {
        setError('');
        alert('Livreur cree avec succes');
        handleCloseModal();
        await refreshDriverData();
      } else {
        throw new Error('Achec de la creation');
      }
    } catch (err: any) {
      console.error('Erreur creation:', err);
      if (Array.isArray(err?.errors) && err.errors.length > 0) {
        const fieldErrors: Record<string, string> = {};
        err.errors.forEach((e: any) => {
          const field = e?.field || e?.path || e?.param;
          if (field && !fieldErrors[field]) {
            fieldErrors[field] = e.message || e.msg || 'Erreur de validation';
          }
        });
        if (Object.keys(fieldErrors).length > 0) {
          setCreateFormErrors(fieldErrors);
        }
      }
      setError(getApiErrorMessage(err, 'Impossible de creer le livreur'));
    } finally {
      setSaveLoading(false);
    }
  };

  const setDriverUpdating = (driverId: string, isUpdating: boolean) => {
    setUpdatingDriverIds((prev) => {
      if (isUpdating) return { ...prev, [driverId]: true };
      const next = { ...prev };
      delete next[driverId];
      return next;
    });
  };

  const handleSave = async () => {
    if (!selectedDriver) {
      setError('Aucun livreur selectionne');
      return;
    }

    // Validation
    if (!validateEditForm()) {
      setError('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    try {
      setSaveLoading(true);
      setError('');

      const token = localStorage.getItem('access_token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const existingCoords = getCoordinatesFromPoint(selectedDriver.current_location);
      const latitudeValue = (editFormData.location_latitude ?? (existingCoords ? String(existingCoords.latitude) : '')).trim();
      const longitudeValue = (editFormData.location_longitude ?? (existingCoords ? String(existingCoords.longitude) : '')).trim();

      const currentLocation =
        latitudeValue === '' && longitudeValue === ''
          ? null
          : {
              type: 'Point',
              coordinates: [Number.parseFloat(longitudeValue), Number.parseFloat(latitudeValue)]
            };
      const profileImageUrl =
        editFormData.profile_image_url !== undefined
          ? editFormData.profile_image_url.trim() || null
          : selectedDriver.profile_image_url || null;

      const updateData = {
        first_name: editFormData.first_name ?? selectedDriver.first_name,
        last_name: editFormData.last_name ?? selectedDriver.last_name,
        email: editFormData.email ?? selectedDriver.email ?? '',
        ...(editFormData.password?.trim() ? { password: editFormData.password.trim() } : {}),
        phone: editFormData.phone ?? selectedDriver.phone,
        vehicle_type: editFormData.vehicle_type ?? selectedDriver.vehicle_type,
        vehicle_plate: editFormData.vehicle_plate ?? selectedDriver.vehicle_plate ?? '',
        license_number: editFormData.license_number ?? selectedDriver.license_number ?? '',
        is_verified: editFormData.is_verified ?? selectedDriver.is_verified,
        is_active: editFormData.is_active ?? selectedDriver.is_active,
        status: editFormData.status ?? selectedDriver.status,
        notes: editFormData.notes ?? selectedDriver.notes ?? '',
        profile_image_url: profileImageUrl,
        locale: editFormData.locale ?? selectedDriver.locale ?? 'fr',
        current_location: currentLocation
      };

      const response = await fetch(`${API_URL}/driver/update/${selectedDriver.id}`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(updateData)
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(getApiErrorMessage(errorData, 'Erreur lors de la mise A  jour'));
      }

      const data = await response.json();

      if (data.success) {
        await refreshDriverData();
        handleCloseModal();
      } else {
        throw new Error('Achec de la mise A  jour');
      }
    } catch (err: any) {
      console.error('Erreur sauvegarde:', err);
      setError(getApiErrorMessage(err, 'Impossible de sauvegarder'));
    } finally {
      setSaveLoading(false);
    }
  };

  const handleApproveDriver = async (driver: Driver) => {
    if (confirm(`Approuver le livreur ${driver.first_name} ${driver.last_name} ?`)) {
      try {
        setSaveLoading(true);
        const token = localStorage.getItem('access_token');
        
        const response = await fetch(`${API_URL}/driver/update/${driver.id}`, {
          method: 'PUT',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            is_verified: true,
            is_active: true,
            status: 'available'
          })
        });

        if (!response.ok) throw new Error('Erreur lors de l\'approbation');

        setError('');
        alert('Livreur approuve avec succes');
        await refreshDriverData();
      } catch (err: any) {
        console.error('Erreur approbation:', err);
        setError(err?.message || 'Impossible d\'approuver le livreur');
      } finally {
        setSaveLoading(false);
      }
    }
  };

  const handleRejectDriver = async (driver: Driver) => {
    const reason = prompt(`Raison du rejet de ${driver.first_name} ${driver.last_name} :`);
    if (reason) {
      try {
        setSaveLoading(true);
        const token = localStorage.getItem('access_token');
        
        const response = await fetch(`${API_URL}/driver/update/${driver.id}`, {
          method: 'PUT',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            is_verified: false,
            is_active: false,
            status: 'suspended',
            notes: `Rejete: ${reason}`
          })
        });

        if (!response.ok) throw new Error('Erreur lors du rejet');

        setError('');
        alert('Livreur rejete');
        await refreshDriverData();
      } catch (err: any) {
        console.error('Erreur rejet:', err);
        setError(err?.message || 'Impossible de rejeter le livreur');
      } finally {
        setSaveLoading(false);
      }
    }
  };

  const handleDriverStatusToggle = async (driver: Driver) => {
    const isSuspended = driver.status === 'suspended' || !driver.is_active;
    const isRejected = isRejectedDriver(driver);
    const nextPayload = isSuspended
      ? {
          is_active: true,
          status: 'available' as DriverStatus,
          ...(isRejected
            ? {
                is_verified: true,
                notes: null
              }
            : {})
        }
      : {
          is_active: false,
          status: 'suspended' as DriverStatus
        };

    const confirmMessage = isSuspended
      ? `Reactiver le livreur ${driver.first_name} ${driver.last_name} ?`
      : `Suspendre le livreur ${driver.first_name} ${driver.last_name} ?`;

    if (!confirm(confirmMessage)) return;

    try {
      setDriverUpdating(driver.id, true);
      setError('');

      const token = localStorage.getItem('access_token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const response = await fetch(`${API_URL}/driver/update/${driver.id}`, {
        method: 'PUT',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          is_verified: isSuspended && isRejected ? true : driver.is_verified,
          ...nextPayload
        })
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Erreur lors de la mise a jour du statut');
      }

      await refreshDriverData();
    } catch (err: any) {
      console.error('Erreur mise a jour statut livreur:', err);
      setError(err?.message || 'Impossible de mettre a jour le statut du livreur');
    } finally {
      setDriverUpdating(driver.id, false);
    }
  };

  const handleDeleteModal = async () => {
    if (!selectedDriver) {
      setError('Aucun livreur selectionne');
      return;
    }

    try {
      setSaveLoading(true);
      setError('');

      const token = localStorage.getItem('access_token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const response = await fetch(`${API_URL}/driver/delete/${selectedDriver.id}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Erreur lors de la suppression');
      }

      const data = await response.json();

      if (data.success) {
        await refreshDriverData();
        handleCloseModal();
      } else {
        throw new Error('Achec de la suppression');
      }
    } catch (err: any) {
      console.error('Erreur suppression:', err);
      setError(err?.message || 'Impossible de supprimer');
    } finally {
      setSaveLoading(false);
    }
  };

  const handlePermanentDeleteRejectedDriver = async (driver: Driver) => {
    const fullName = `${driver.first_name || ''} ${driver.last_name || ''}`.trim() || driver.driver_code || 'ce livreur';

    const confirmation = prompt(
      `Suppression DEFINITIVE (compte + profil) de ${fullName}.\nTapez SUPPRIMER pour confirmer :`
    );

    if (confirmation !== 'SUPPRIMER') return;

    try {
      setSaveLoading(true);
      setError('');

      const token = localStorage.getItem('access_token');
      if (!token) {
        throw new Error('Non authentifie');
      }

      const response = await fetch(`${API_URL}/driver/permanent-delete/${driver.id}`, {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      });

      const data = await response.json().catch(() => ({}));

      if (!response.ok) {
        throw new Error(data?.message || 'Erreur lors de la suppression definitive');
      }

      alert('Livreur supprime definitivement');
      await refreshDriverData();
    } catch (err: any) {
      console.error('Erreur suppression definitive livreur:', err);
      setError(err?.message || 'Impossible de supprimer definitivement le livreur');
    } finally {
      setSaveLoading(false);
    }
  };

  const handleInputChange = (field: keyof EditDriverForm, value: any) => {
    setEditFormData((prev) => ({
      ...prev,
      [field]: value
    }));

    // Clear field error when user starts typing
    if (editFormErrors[field]) {
      setEditFormErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });
    }
  };

  const handleCreateInputChange = (field: keyof CreateDriverForm, value: any) => {
    setCreateForm((prev) => ({
      ...prev,
      [field]: value
    }));

    // Clear field error when user starts typing
    if (createFormErrors[field]) {
      setCreateFormErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[field];
        return newErrors;
      });
    }
  };

  // Image upload functions
  const handleImageUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      setError('Veuillez selectionner une image valide');
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      setError("L'image ne doit pas depasser 5 MB");
      return;
    }

    setUploadingImage(true);
    setError('');

    try {
      const formData = new FormData();
      formData.append('file', file);

      const token = localStorage.getItem('access_token');
      const response = await fetch(`${API_URL}/api/upload`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`
        },
        body: formData
      });

      if (!response.ok) {
        throw new Error("Achec de l'upload de l'image");
      }

      const data = await response.json();

      setCreateForm((prev) => ({ ...prev, profile_image_url: data.url }));
      setImagePreview(URL.createObjectURL(file));
      setError('');
    } catch (err: any) {
      console.error('Error uploading image:', err);
      setError(err?.message || "Erreur lors de l'upload de l'image");
    } finally {
      setUploadingImage(false);
    }
  };

  const handleEditImageUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
      setError('Veuillez selectionner une image valide');
      return;
    }

    if (file.size > 5 * 1024 * 1024) {
      setError("L'image ne doit pas depasser 5 MB");
      return;
    }

    setEditUploadingImage(true);
    setError('');

    try {
      const formData = new FormData();
      formData.append('file', file);

      const token = localStorage.getItem('access_token');
      const response = await fetch(`${API_URL}/api/upload`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`
        },
        body: formData
      });

      if (!response.ok) {
        throw new Error("Achec de l'upload de l'image");
      }

      const data = await response.json();

      setEditFormData((prev) => ({ ...prev, profile_image_url: data.url }));
      setEditImagePreview(URL.createObjectURL(file));
      setError('');
    } catch (err: any) {
      console.error('Error uploading image:', err);
      setError(err?.message || "Erreur lors de l'upload de l'image");
    } finally {
      setEditUploadingImage(false);
    }
  };

  const removeImage = () => {
    setCreateForm((prev) => ({ ...prev, profile_image_url: '' }));
    setImagePreview(null);
  };

  const removeEditImage = () => {
    setEditFormData((prev) => ({ ...prev, profile_image_url: '' }));
    setEditImagePreview(null);
  };

  const formatDate = (dateString: string) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('fr-FR', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getStatusColor = (status: DriverStatus) => {
    switch (status) {
      case 'available':
        return 'bg-green-100 text-green-800';
      case 'busy':
        return 'bg-blue-100 text-blue-800';
      case 'offline':
        return 'bg-gray-100 text-gray-800';
      case 'suspended':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getVehicleIcon = (vehicleType: VehicleType) => {
    return <Car className="w-4 h-4" />;
  };

  const isDriverListTab =
    activeTab === 'all' || activeTab === 'suspended' || activeTab === 'rejected';
  const currentDriverRows =
    activeTab === 'suspended'
      ? filteredSuspendedDrivers
      : activeTab === 'rejected'
        ? filteredRejectedDrivers
        : drivers;
  const driverSearchPlaceholder =
    activeTab === 'rejected'
      ? 'Rechercher un livreur rejete...'
      : activeTab === 'suspended'
        ? 'Rechercher un livreur suspendu...'
        : 'Rechercher par nom, code, email ou telephone...';
  const driverSummary =
    activeTab === 'all'
      ? `${drivers.length} livreur${drivers.length !== 1 ? 's' : ''} affiche${drivers.length !== 1 ? 's' : ''} sur ${totalDriversCount || totalCount}`
      : activeTab === 'suspended'
        ? `${suspendedDrivers.length} livreur${suspendedDrivers.length !== 1 ? 's' : ''} suspendu${suspendedDrivers.length !== 1 ? 's' : ''}`
        : activeTab === 'rejected'
          ? `${rejectedDrivers.length} livreur${rejectedDrivers.length !== 1 ? 's' : ''} rejete${rejectedDrivers.length !== 1 ? 's' : ''}`
          : activeTab === 'email-unconfirmed'
            ? `${pendingUnconfirmedEmailDrivers.length} compte${pendingUnconfirmedEmailDrivers.length !== 1 ? 's' : ''} en attente de confirmation email`
          : activeTab === 'warnings'
            ? `${warningDrivers.length} livreur${warningDrivers.length !== 1 ? 's' : ''} averti${warningDrivers.length !== 1 ? 's' : ''}`
            : `${pendingDrivers.length} demande${pendingDrivers.length !== 1 ? 's' : ''} en attente`;
  const driverEmptyMessage =
    activeTab === 'rejected'
      ? searchTerm.trim()
        ? 'Aucun livreur rejete ne correspond a cette recherche'
        : 'Aucun livreur rejete'
      : activeTab === 'suspended'
        ? searchTerm.trim()
          ? 'Aucun livreur suspendu ne correspond a cette recherche'
          : 'Aucun livreur suspendu'
        : 'Essayez de modifier vos criteres de recherche';

  const selectedDriverCoords = selectedDriver
    ? getCoordinatesFromPoint(selectedDriver.current_location)
    : null;
  const selectedDriverImageUrl = selectedDriver
    ? (
        modalType === 'edit'
          ? (editImagePreview ||
            (editFormData.profile_image_url !== undefined
              ? editFormData.profile_image_url
              : selectedDriver.profile_image_url) ||
            '')
          : selectedDriver.profile_image_url || ''
      )
    : '';

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <div className="bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div className="max-w-none mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div className="w-full">
              <div className="flex items-center gap-4">
                <h1 className="text-2xl font-bold text-gray-900">Gestion des Livreurs</h1>
                {activeTab === 'all' && totalDriversCount > 0 && (
                  <div className="bg-blue-50 border border-blue-200 rounded-lg px-4 py-2">
                    <p className="text-xs text-blue-600 font-medium">Total livreurs</p>
                    <p className="text-lg font-bold text-blue-700">{totalDriversCount}</p>
                  </div>
                )}
              </div>
              <p className="mt-1 text-sm text-gray-500">
                {driverSummary}
              </p>
            </div>
            <div className="flex flex-wrap gap-2 w-full md:w-auto justify-end">
              <button
                onClick={() => {
                  setError('');
                  setModalType('create');
                  setShowModal(true);
                }}
                className="w-full sm:w-auto px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors flex items-center justify-center gap-2"
              >
                <Plus className="w-5 h-5" />
                Nouveau Livreur
              </button>
              <button
                onClick={handleRefresh}
                disabled={loading}
                className="w-full sm:w-auto px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors flex items-center justify-center"
              >
                {loading ? 'Chargement...' : 'Actualiser'}
              </button>
            </div>
          </div>

          {/* Onglets */}
          <div className="flex gap-4 border-b mt-6 overflow-x-auto">
            <button
              onClick={() => setActiveTab('all')}
              className={`pb-3 px-1 border-b-2 font-medium transition-colors ${
                activeTab === 'all'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              Tous les livreurs ({totalDriversCount || totalCount || drivers.length})
            </button>
            <button
              onClick={() => setActiveTab('email-unconfirmed')}
              className={`pb-3 px-1 border-b-2 font-medium transition-colors relative ${
                activeTab === 'email-unconfirmed'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              Emails non confirmes
              {pendingUnconfirmedEmailDrivers.length > 0 && (
                <span className="ml-2 px-2 py-0.5 bg-amber-500 text-white text-xs rounded-full">
                  {pendingUnconfirmedEmailDrivers.length}
                </span>
              )}
            </button>
            <button
              onClick={() => setActiveTab('suspended')}
              className={`pb-3 px-1 border-b-2 font-medium transition-colors ${
                activeTab === 'suspended'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              Suspendus
              {suspendedDrivers.length > 0 && (
                <span className="ml-2 px-2 py-0.5 bg-amber-500 text-white text-xs rounded-full">
                  {suspendedDrivers.length}
                </span>
              )}
            </button>
            <button
              onClick={() => setActiveTab('rejected')}
              className={`pb-3 px-1 border-b-2 font-medium transition-colors ${
                activeTab === 'rejected'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              Rejetes
              {rejectedDrivers.length > 0 && (
                <span className="ml-2 px-2 py-0.5 bg-red-500 text-white text-xs rounded-full">
                  {rejectedDrivers.length}
                </span>
              )}
            </button>
            <button
              onClick={() => setActiveTab('warnings')}
              className={`pb-3 px-1 border-b-2 font-medium transition-colors ${
                activeTab === 'warnings'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              Avertissements
              {warningDrivers.length > 0 && (
                <span className="ml-2 px-2 py-0.5 bg-amber-500 text-white text-xs rounded-full">
                  {warningDrivers.length}
                </span>
              )}
            </button>
            <button
              onClick={() => setActiveTab('requests')}
              className={`pb-3 px-1 border-b-2 font-medium transition-colors relative ${
                activeTab === 'requests'
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              Demandes en attente
              {pendingDrivers.length > 0 && (
                <span className="ml-2 px-2 py-0.5 bg-red-500 text-white text-xs rounded-full">
                  {pendingDrivers.length}
                </span>
              )}
            </button>
          </div>

          {/* Message d'erreur global */}
          {error && !showModal && (
            <div className="mt-4 bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <p className="text-sm font-medium text-red-800">Erreur</p>
                <p className="text-sm text-red-700 mt-1">{error}</p>
              </div>
            </div>
          )}

          {/* Barre de recherche et filtres */}
          {isDriverListTab && (
            <div className="mt-6 space-y-4">
              <div className="flex flex-col sm:flex-row gap-4">
                <div className="flex-1 relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type="text"
                    placeholder={driverSearchPlaceholder}
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                  />
                </div>
                {activeTab === 'all' && (
                  <select
                    value={filterStatus}
                    onChange={(e) =>
                      setFilterStatus(e.target.value as typeof filterStatus)
                    }
                    className="w-full sm:w-60 px-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none bg-white"
                  >
                    <option value="all">Tous les statuts</option>
                    <option value="available">Disponibles</option>
                    <option value="busy">Occupes</option>
                    <option value="offline">Hors ligne</option>
                    <option value="verified">Verifies</option>
                  </select>
                )}
              </div>
              
              {activeTab === 'all' && (
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-gray-700">Afficher:</span>
                    <select
                      value={pageSize}
                      onChange={(e) => {
                        setPageSize(Number(e.target.value));
                        setCurrentPage(1);
                      }}
                      className="px-3 py-1.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none bg-white text-sm"
                    >
                      <option value="10">10</option>
                      <option value="20">20</option>
                      <option value="50">50</option>
                      <option value="100">100</option>
                    </select>
                    <span className="text-sm text-gray-700">par page</span>
                  </div>
                </div>
              )}
            </div>
          )}

          {activeTab === 'warnings' && (
            <div className="mt-6">
              <div className="flex flex-col sm:flex-row gap-4">
                <div className="flex-1 relative">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    type="text"
                    placeholder="Rechercher un livreur averti..."
                    value={warningSearchTerm}
                    onChange={(e) => setWarningSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                  />
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Contenu principal */}
      <div className="max-w-none mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          </div>
        ) : isDriverListTab ? (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Livreur
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Contact
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Vehicule
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Performance
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Statut
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Inscription
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {currentDriverRows.map((driver) => (
                    <tr key={driver.id} className="hover:bg-gray-50 transition-colors">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center">
                         <img
                            src={
                              driver.profile_image_url ||
                              `https://ui-avatars.com/api/?name=${driver.first_name}+${driver.last_name}&background=16a34a&color=fff`
                            }
                            alt={`${driver.first_name} ${driver.last_name}`}
                            className="w-10 h-10 rounded-full"
                          />
                          <div className="ml-4">
                            <div className="text-sm font-medium text-gray-900">
                              {driver.first_name} {driver.last_name}
                            </div>
                            <div className="text-xs text-gray-500 font-mono">
                              {driver.driver_code}
                            </div>
                            <div className="flex items-center gap-2 mt-1">
                              {driver.is_verified && (
                                <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                                  <UserCheck className="w-3 h-3 mr-1" />
                                  Verifie
                                </span>
                              )}
                              {driver.cancellation_count > 0 && (
                                <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-orange-100 text-orange-800">
                                  as i {driver.cancellation_count} annulation{driver.cancellation_count > 1 ? 's' : ''}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">
                          <div className="flex items-center gap-2 mb-1">
                            <Phone className="w-4 h-4 text-gray-400" />
                            {driver.phone || 'N/A'}
                          </div>
                          {driver.email && (
                            <div className="flex items-center gap-2">
                              <Mail className="w-4 h-4 text-gray-400" />
                              <span className="text-xs">{driver.email}</span>
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-900">
                          <div className="flex items-center gap-2 mb-1">
                            {getVehicleIcon(driver.vehicle_type)}
                            <span className="capitalize">{driver.vehicle_type}</span>
                          </div>
                          {driver.vehicle_plate && (
                            <div className="text-xs text-gray-500 font-mono">
                              {driver.vehicle_plate}
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm">
                          <div className="flex items-center gap-2 mb-1">
                            <Star className="w-4 h-4 text-yellow-500" />
                            <span className="font-semibold">
                              {driver.rating !== null && driver.rating !== undefined
                                ? parseFloat(String(driver.rating)).toFixed(1)
                                : '0.0'}
                            </span>
                          </div>
                          <div className="flex items-center gap-2 text-xs text-gray-500">
                            <TrendingUp className="w-3 h-3" />
                            {driver.total_deliveries} livraison{driver.total_deliveries > 1 ? 's' : ''}
                          </div>
                          <div className="flex items-center gap-2 text-xs text-blue-600 mt-1">
                            <Activity className="w-3 h-3" />
                            {driver.active_orders.length}/{driver.max_orders_capacity} actives
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(
                            driver.status
                          )}`}
                        >
                          {driver.status === 'available' && 'Disponible'}
                          {driver.status === 'busy' && 'Occupe'}
                          {driver.status === 'offline' && 'Hors ligne'}
                          {driver.status === 'suspended' && 'Suspendu'}
                        </span>
                        {driver.last_active_at && (
                          <div className="text-xs text-gray-500 mt-1">
                            Actif: {formatDate(driver.last_active_at)}
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        <div className="flex items-center gap-2">
                          <Calendar className="w-4 h-4" />
                          {formatDate(driver.created_at)}
                        </div>
                      </td>
	                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
	                        <div className="flex items-center justify-end gap-2">
	                          {(driver.status === 'suspended' || !driver.is_active) && (
	                            <button
	                              onClick={() => handleDriverStatusToggle(driver)}
	                              disabled={Boolean(updatingDriverIds[driver.id])}
	                              className="inline-flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-semibold bg-green-50 text-green-700 hover:bg-green-100 transition-colors disabled:cursor-not-allowed disabled:opacity-60"
	                              title="Reactiver"
	                            >
	                              <UserCheck className="w-3.5 h-3.5" />
	                              Reactiver
	                            </button>
	                          )}
	                          {activeTab !== 'rejected' && driver.is_active && driver.status !== 'suspended' && (
	                            <button
	                              onClick={() => handleDriverStatusToggle(driver)}
	                              disabled={Boolean(updatingDriverIds[driver.id])}
	                              className="inline-flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-semibold bg-amber-50 text-amber-700 hover:bg-amber-100 transition-colors disabled:cursor-not-allowed disabled:opacity-60"
	                              title="Suspendre"
	                            >
	                              <UserX className="w-3.5 h-3.5" />
	                              Suspendre
	                            </button>
	                          )}
	                          <button
	                            onClick={() => handleAction(driver, 'view')}
	                            className="text-gray-600 hover:text-gray-900 p-1.5 rounded-lg hover:bg-gray-100 transition-colors"
	                            title="Voir les details"
	                          >
	                            <Eye className="w-4 h-4" />
	                          </button>
	                          {activeTab !== 'rejected' && (
	                            <button
	                              onClick={() => handleAction(driver, 'edit')}
	                              className="text-blue-600 hover:text-blue-900 p-1.5 rounded-lg hover:bg-blue-50 transition-colors"
	                              title="Modifier"
	                            >
	                              <Edit className="w-4 h-4" />
	                            </button>
	                          )}
	                          {activeTab === 'rejected' ? (
	                            <button
	                              onClick={() => handlePermanentDeleteRejectedDriver(driver)}
	                              disabled={saveLoading}
	                              className="inline-flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-semibold bg-red-50 text-red-700 hover:bg-red-100 transition-colors disabled:opacity-50"
	                              title="Suppression definitive"
	                            >
	                              <Trash2 className="w-3.5 h-3.5" />
	                              Supprimer definitivement
	                            </button>
	                          ) : (
	                            <button
	                              onClick={() => handleRejectDriver(driver)}
	                              disabled={saveLoading}
	                              className="inline-flex items-center gap-1 rounded-lg px-2.5 py-1.5 text-xs font-semibold bg-red-50 text-red-700 hover:bg-red-100 transition-colors disabled:cursor-not-allowed disabled:opacity-60"
	                              title="Supprimer (mettre dans la liste des rejetes)"
	                            >
	                              <Trash2 className="w-4 h-4" />
	                              Supprimer
	                            </button>
	                          )}
	                        </div>
	                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {currentDriverRows.length === 0 && (
              <div className="text-center py-12">
                <UserX className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-sm font-medium text-gray-900">
                  {activeTab === 'rejected'
                    ? 'Aucun livreur rejete'
                    : activeTab === 'suspended'
                      ? 'Aucun livreur suspendu'
                      : 'Aucun livreur trouve'}
                </h3>
                <p className="mt-1 text-sm text-gray-500">
                  {driverEmptyMessage}
                </p>
              </div>
            )}

            {/* Pagination */}
            {activeTab === 'all' && drivers.length > 0 && (
              <div className="bg-gray-50 px-6 py-4 border-t border-gray-200 flex items-center justify-between">
                <div className="text-sm text-gray-700">
                  Affichage de <span className="font-medium">{(currentPage - 1) * pageSize + 1}</span> A {' '}
                  <span className="font-medium">
                    {Math.min(currentPage * pageSize, totalCount)}
                  </span>{' '}
                  sur <span className="font-medium">{totalCount}</span> livreur
                  {totalCount !== 1 ? 's' : ''}
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setCurrentPage((prev) => Math.max(1, prev - 1))}
                    disabled={currentPage === 1}
                    className="px-3 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-1 transition-colors"
                  >
                    <ChevronLeft className="w-4 h-4" />
                    <span className="hidden sm:inline">Precedent</span>
                  </button>
                  <div className="flex items-center gap-1">
                    {Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
                      let pageNum;
                      if (totalPages <= 5) {
                        pageNum = i + 1;
                      } else if (currentPage <= 3) {
                        pageNum = i + 1;
                      } else if (currentPage >= totalPages - 2) {
                        pageNum = totalPages - 4 + i;
                      } else {
                        pageNum = currentPage - 2 + i;
                      }
                      return (
                        <button
                          key={pageNum}
                          onClick={() => setCurrentPage(pageNum)}
                          className={`px-3 py-2 text-sm rounded-lg transition-colors ${
                            currentPage === pageNum
                              ? 'bg-blue-600 text-white'
                              : 'border border-gray-300 hover:bg-gray-50'
                          }`}
                        >
                          {pageNum}
                        </button>
                      );
                    })}
                  </div>
                  <button
                    onClick={() =>
                      setCurrentPage((prev) => Math.min(totalPages, prev + 1))
                    }
                    disabled={currentPage === totalPages}
                    className="px-3 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-1 transition-colors"
                  >
                    <span className="hidden sm:inline">Suivant</span>
                    <ChevronRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )}
          </div>
        ) : activeTab === 'warnings' ? (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Livreur
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Contact
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Statut
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Avertissements
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Derniere alerte
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredWarningDrivers.map((entry) => {
                    const driver = entry.driver;
                    const fullName = driver
                      ? `${driver.first_name || ''} ${driver.last_name || ''}`.trim() || 'Livreur'
                      : 'Livreur inconnu';
                    return (
                      <tr key={entry.driver_id} className="hover:bg-gray-50 transition-colors">
                        <td className="px-6 py-4">
                          <div className="text-sm font-semibold text-gray-900">
                            {fullName}
                          </div>
                          <div className="text-xs text-gray-500">
                            {driver?.driver_code || 'Code inconnu'}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm text-gray-700">
                            {driver?.phone || 'Telephone non renseigne'}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(driver?.status || 'offline')}`}>
                            {driver?.status || 'offline'}
                          </span>
                          <div className="text-xs text-gray-500 mt-1">
                            {driver?.is_active ? 'Actif' : 'Inactif'}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-sm font-semibold text-amber-700">
                            {entry.warnings_total}
                          </div>
                          <div className="text-xs text-gray-500">
                            Retards: {entry.warnings_delay} | Annulations: {entry.warnings_cancellations}
                          </div>
                          <div className="text-xs text-gray-500">
                            Non resolues: {entry.warnings_unresolved || 0}
                          </div>
                        </td>
                        <td className="px-6 py-4 text-sm text-gray-700">
                          {entry.last_warning_at ? formatDate(entry.last_warning_at) : '-'}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            {filteredWarningDrivers.length === 0 && (
              <div className="text-center py-12">
                <p className="text-gray-500">
                  {warningSearchTerm.trim()
                    ? 'Aucun livreur trouve pour cette recherche'
                    : 'Aucun livreur n\'a ete averti'}
                </p>
              </div>
            )}
          </div>
        ) : (
          /* Onglet Demandes en attente */
          <div>
            {activeTab === 'email-unconfirmed' ? (
              <div className="mb-6">
                <div className="flex justify-end">
                  <div className="bg-amber-50 border border-amber-200 rounded-lg px-4 py-2">
                    <p className="text-xs text-amber-700 font-medium">Emails non confirmes</p>
                    <p className="text-lg font-bold text-amber-800">
                      {pendingUnconfirmedEmailDrivers.length}
                    </p>
                  </div>
                </div>
              </div>
            ) : (
              <div className="mb-6">
                <h2 className="text-lg font-semibold text-gray-900 mb-2">
                  Demandes de livreurs en attente
                </h2>
                <div className="flex flex-wrap gap-4 items-center">
                  <p className="text-gray-600">
                    Consultez et gerez les demandes d&apos;inscription des nouveaux livreurs.
                  </p>
                  <div className="ml-auto flex gap-4">
                    <div className="bg-blue-50 border border-blue-200 rounded-lg px-4 py-2">
                      <p className="text-xs text-blue-600 font-medium">Total demandes</p>
                      <p className="text-lg font-bold text-blue-700">{pendingDrivers.length}</p>
                    </div>
                    <div className="bg-green-50 border border-green-200 rounded-lg px-4 py-2">
                      <p className="text-xs text-green-600 font-medium">Total livreurs</p>
                      <p className="text-lg font-bold text-green-700">{totalDriversCount}</p>
                    </div>
                  </div>
                </div>
              </div>
            )}

            <div className="mb-6">
              <div className="relative w-full max-w-md">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  type="text"
                  placeholder="Rechercher par nom, code, email ou telephone..."
                  value={pendingSearchTerm}
                  onChange={(e) => setPendingSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent outline-none"
                />
              </div>
            </div>

            {(activeTab === 'email-unconfirmed'
              ? filteredPendingUnconfirmedEmailDrivers
              : filteredPendingDrivers
            ).length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {(activeTab === 'email-unconfirmed'
                  ? filteredPendingUnconfirmedEmailDrivers
                  : filteredPendingDrivers
                ).map((driver) => (
                  <div key={driver.id} className="bg-white rounded-lg shadow p-4">
                    <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-2 mb-3">
                      <div className="flex-1 min-w-0">
                        <h3 className="font-semibold text-gray-900 truncate">
                          {driver.first_name} {driver.last_name}
                        </h3>
                        <p className="text-sm text-gray-500 font-mono mt-1 truncate">
                          {driver.driver_code}
                        </p>
                        <p className="text-sm text-gray-600 mt-1 capitalize line-clamp-1">
                          {driver.vehicle_type} - {driver.vehicle_plate || 'N/A'}
                        </p>
                      </div>
                      <span className="text-xs text-gray-500 whitespace-nowrap flex-shrink-0">
                        {formatDate(driver.created_at)}
                      </span>
                    </div>

                    <div className="space-y-2 text-sm text-gray-600 mb-4">
                      <div className="flex items-center gap-2">
                        <Phone className="w-4 h-4 text-gray-400 flex-shrink-0" />
                        <span className="break-all">{driver.phone}</span>
                      </div>
                      {driver.email && (
                        <div className="flex items-start gap-2">
                          <Mail className="w-4 h-4 text-gray-400 flex-shrink-0 mt-0.5" />
                          <span className="text-xs break-all">{driver.email}</span>
                        </div>
                      )}
                      {driver.license_number && (
                        <div className="text-xs text-gray-500 truncate">
                          Permis: {driver.license_number}
                        </div>
                      )}
                    </div>

                    <div className="flex flex-col sm:flex-row gap-2">
                      <button
                        onClick={() => handleAction(driver, 'view')}
                        className="flex-1 px-3 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 flex items-center justify-center gap-2 text-sm"
                      >
                        <Eye className="w-4 h-4" />
                        <span className="whitespace-nowrap">Details</span>
                      </button>
                      {hasVerifiedEmail(driver.email_verified_at) ? (
                        <button
                          onClick={() => handleApproveDriver(driver)}
                          disabled={saveLoading}
                          className="flex-1 px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 flex items-center justify-center gap-2 text-sm"
                        >
                          <UserCheck className="w-4 h-4" />
                          <span className="whitespace-nowrap">Accepter</span>
                        </button>
                      ) : null}
                      <button
                        onClick={() => handleRejectDriver(driver)}
                        disabled={saveLoading}
                        className="flex-1 px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 flex items-center justify-center gap-2 text-sm"
                      >
                        <UserX className="w-4 h-4" />
                        <span className="whitespace-nowrap">Rejeter</span>
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-12 bg-white rounded-lg">
                <UserCheck className="w-12 h-12 text-green-500 mx-auto mb-3" />
                <p className="text-gray-500">
                  {(activeTab === 'email-unconfirmed'
                    ? pendingUnconfirmedEmailDrivers.length
                    : pendingDrivers.length) === 0
                    ? activeTab === 'email-unconfirmed'
                      ? 'Aucun livreur en attente de confirmation email'
                      : 'Aucune demande en attente'
                    : 'Aucune demande trouvee pour cette recherche'}
                </p>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Modal Create Driver */}
      {showModal && modalType === 'create' && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between sticky top-0 bg-white">
              <h2 className="text-xl font-bold text-gray-900">Creer un Nouveau Livreur</h2>
              <button
                onClick={handleCloseModal}
                className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="px-6 py-4">
              <ModalErrorNotice message={error} onClose={() => setError('')} />

              <div className="space-y-6">
                {/* Informations de compte */}
                <div className="bg-gray-50 p-4 rounded-lg">
                  <h3 className="text-lg font-semibold mb-4">Informations du compte</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Email <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="email"
                        value={createForm.email}
                        onChange={(e) => handleCreateInputChange('email', e.target.value)}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent ${
                          createFormErrors.email 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                        placeholder="driver@example.com"
                        required
                      />
                      {createFormErrors.email && (
                        <p className="text-red-500 text-xs mt-1">{createFormErrors.email}</p>
                      )}
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Mot de passe <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="password"
                        value={createForm.password}
                        onChange={(e) => handleCreateInputChange('password', e.target.value)}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent ${
                          createFormErrors.password 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                        placeholder="aaaaaaaa"
                        required
                      />
                      {createFormErrors.password ? (
                        <p className="text-red-500 text-xs mt-1">{createFormErrors.password}</p>
                      ) : (
                        <p className="text-xs text-gray-500 mt-1">Minimum 6 caracteres</p>
                      )}
                    </div>
                  </div>
                </div>

                {/* Informations personnelles */}
                <div className="bg-gray-50 p-4 rounded-lg">
                  <h3 className="text-lg font-semibold mb-4">Informations personnelles</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Prenom <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="text"
                        value={createForm.first_name}
                        onChange={(e) => handleCreateInputChange('first_name', e.target.value)}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent ${
                          createFormErrors.first_name 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                        placeholder="Mohamed"
                        required
                      />
                      {createFormErrors.first_name && (
                        <p className="text-red-500 text-xs mt-1">{createFormErrors.first_name}</p>
                      )}
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Nom <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="text"
                        value={createForm.last_name}
                        onChange={(e) => handleCreateInputChange('last_name', e.target.value)}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent ${
                          createFormErrors.last_name 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                        placeholder="Benali"
                        required
                      />
                      {createFormErrors.last_name && (
                        <p className="text-red-500 text-xs mt-1">{createFormErrors.last_name}</p>
                      )}
                    </div>
                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Telephone <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="tel"
                        value={createForm.phone}
                        onChange={(e) => handleCreateInputChange('phone', e.target.value)}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent ${
                          createFormErrors.phone 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                        placeholder="+213 XXX XXX XXX"
                        required
                      />
                      {createFormErrors.phone && (
                        <p className="text-red-500 text-xs mt-1">{createFormErrors.phone}</p>
                      )}
                    </div>

                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Langue <span className="text-red-500">*</span>
                      </label>
                      <select
                        value={createForm.locale}
                        onChange={(e) => handleCreateInputChange('locale', e.target.value)}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent ${
                          createFormErrors.locale 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                      >
                        {LOCALE_OPTIONS.map((option) => (
                          <option key={option.value} value={option.value}>
                            {option.label}
                          </option>
                        ))}
                      </select>
                      {createFormErrors.locale && (
                        <p className="text-red-500 text-xs mt-1">{createFormErrors.locale}</p>
                      )}
                    </div>
                  </div>
                </div>

                {/* Photo de profil */}
                <div className="bg-gray-50 p-4 rounded-lg">
                  <h3 className="text-lg font-semibold mb-4">Photo de profil</h3>
                  <div className="space-y-4">
                    {(imagePreview || createForm.profile_image_url) && (
                      <div className="relative w-full h-48 rounded-lg overflow-hidden bg-gray-100 border-2 border-gray-200">
                        <img
                          src={imagePreview || createForm.profile_image_url}
                          alt="Preview"
                          className="w-full h-full object-cover"
                        />
                        <button
                          type="button"
                          onClick={removeImage}
                          className="absolute top-2 right-2 p-2 bg-red-500 text-white rounded-full hover:bg-red-600 transition-colors shadow-lg"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </div>
                    )}

                    <div className="flex gap-3">
                      <label className="flex-1 cursor-pointer">
                        <div className="flex items-center justify-center gap-2 px-4 py-3 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-500 hover:bg-blue-50 transition-colors">
                          {uploadingImage ? (
                            <>
                              <div className="animate-spin rounded-full h-5 w-5 border-2 border-gray-300 border-t-blue-600"></div>
                              <span className="text-sm text-gray-600">
                                Upload en cours...
                              </span>
                            </>
                          ) : (
                            <>
                              <svg
                                className="w-5 h-5 text-gray-600"
                                fill="none"
                                stroke="currentColor"
                                viewBox="0 0 24 24"
                              >
                                <path
                                  strokeLinecap="round"
                                  strokeLinejoin="round"
                                  strokeWidth="2"
                                  d="M12 4v16m8-8H4"
                                />
                              </svg>
                              <span className="text-sm text-gray-600">
                                {imagePreview || createForm.profile_image_url
                                  ? 'Changer l\'image'
                                  : 'Telecharger une image'}
                              </span>
                            </>
                          )}
                        </div>
                        <input
                          type="file"
                          accept="image/*"
                          onChange={handleImageUpload}
                          className="hidden"
                          disabled={uploadingImage}
                        />
                      </label>

                      {/* Manual URL Input */}
                      <button
                        type="button"
                        onClick={() => {
                          const url = prompt("Entrez l'URL de l'image:");
                          if (url) {
                            setCreateForm({...createForm, profile_image_url: url});
                            setImagePreview(null);
                          }
                        }}
                        className="px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                        title="Entrer une URL manuellement"
                      >
                        <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                        </svg>
                      </button>
                    </div>

                    <p className="text-xs text-gray-500">
                      Formats acceptes: JPG, PNG, GIF. Taille max: 5 MB
                    </p>
                  </div>
                </div>

                {/* Informations du vehicule */}
                <div className="bg-gray-50 p-4 rounded-lg">
                  <h3 className="text-lg font-semibold mb-4">Informations du vehicule</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Type de vehicule
                      </label>
                      <select
                        value={createForm.vehicle_type}
                        onChange={(e) => handleCreateInputChange('vehicle_type', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      >
                        <option value="motorcycle">Moto</option>
                        <option value="bicycle">Velo</option>
                        <option value="scooter">Scooter</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Plaque d&apos;immatriculation
                      </label>
                      <input
                        type="text"
                        value={createForm.vehicle_plate}
                        onChange={(e) => handleCreateInputChange('vehicle_plate', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        placeholder="ABC-1234"
                      />
                    </div>
                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Numero de permis
                      </label>
                      <input
                        type="text"
                        value={createForm.license_number}
                        onChange={(e) => handleCreateInputChange('license_number', e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        placeholder="123456789"
                      />
                    </div>
                  </div>
                </div>

                {/* Options */}
                <div className="bg-gray-50 p-4 rounded-lg">
                  <h3 className="text-lg font-semibold mb-4">Options</h3>
                  <div className="flex flex-col gap-3">
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={createForm.is_verified}
                        onChange={(e) => handleCreateInputChange('is_verified', e.target.checked)}
                        className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                      />
                      <span className="text-sm font-medium text-gray-700">
                        Compte verifie
                      </span>
                    </label>
                    <label className="flex items-center gap-2">
                      <input
                        type="checkbox"
                        checked={createForm.is_active}
                        onChange={(e) => handleCreateInputChange('is_active', e.target.checked)}
                        className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                      />
                      <span className="text-sm font-medium text-gray-700">
                        Compte actif
                      </span>
                    </label>
                  </div>
                </div>
              </div>
            </div>

            {/* Footer */}
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end gap-3 sticky bottom-0 bg-white">
              <button
                onClick={handleCloseModal}
                disabled={saveLoading}
                className="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors disabled:opacity-50"
              >
                Annuler
              </button>
              <button
                onClick={handleCreateDriver}
                disabled={saveLoading || uploadingImage}
                className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50 flex items-center gap-2"
              >
                {saveLoading ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                    Creation...
                  </>
                ) : (
                  <>
                    <Save className="w-4 h-4" />
                    Creer le livreur
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal View/Edit/Delete Driver */}
      {showModal && selectedDriver && modalType !== 'create' && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            {/* Header */}
            <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between sticky top-0 bg-white">
              <h2 className="text-xl font-bold text-gray-900">
                {modalType === 'view' && 'Details du Livreur'}
                {modalType === 'edit' && 'Modifier le Livreur'}
                {modalType === 'delete' && 'Confirmer la Suppression'}
              </h2>
              <button
                onClick={handleCloseModal}
                className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            {/* Content */}
            <div className="px-6 py-4">
              {modalType === 'edit' && (
                <ModalErrorNotice message={error} onClose={() => setError('')} />
              )}

              {modalType === 'delete' ? (
                <div className="text-center py-4">
                  <div className="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100 mb-4">
                    <Trash2 className="h-6 w-6 text-red-600" />
                  </div>
                  <h3 className="text-lg font-medium text-gray-900 mb-2">
                    Êtes-vous sûr de vouloir supprimer ce livreur ?
                  </h3>
                  <p className="text-sm text-gray-500 mb-2">
                    <strong>{selectedDriver.first_name} {selectedDriver.last_name}</strong> ({selectedDriver.driver_code})
                  </p>
                  <p className="text-sm text-gray-500 mb-6">
                    Cette action est irreversible. Toutes les donnees du livreur
                    seront supprimees.
                  </p>
                  <div className="flex gap-3 justify-center">
                    <button
                      onClick={handleCloseModal}
                      disabled={saveLoading}
                      className="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors disabled:opacity-50"
                    >
                      Annuler
                    </button>
                    <button
                      onClick={handleDeleteModal}
                      disabled={saveLoading}
                      className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50 flex items-center gap-2"
                    >
                      {saveLoading ? (
                        <>
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                          Suppression...
                        </>
                      ) : (
                        'Supprimer'
                      )}
                    </button>
                  </div>
                </div>
              ) : (
                <div className="space-y-6">
                  {/* Photo de profil */}
                  <div className="flex items-center gap-4">
                    <div className="relative">
                      <img
                        src={
                          selectedDriverImageUrl ||
                          `https://ui-avatars.com/api/?name=${selectedDriver.first_name}+${selectedDriver.last_name}&background=16a34a&color=fff`
                        }
                        alt={`${selectedDriver.first_name} ${selectedDriver.last_name}`}
                        className="w-20 h-20 rounded-full object-cover border-2 border-gray-200"
                      />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900">
                        {selectedDriver.first_name} {selectedDriver.last_name}
                      </h3>
                      <p className="text-sm text-gray-500 font-mono">
                        {selectedDriver.driver_code}
                      </p>
                      <div className="flex items-center gap-2 mt-1">
                        {selectedDriver.is_verified ? (
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            <UserCheck className="w-3 h-3 mr-1" />
                            Compte verifie
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                            <UserX className="w-3 h-3 mr-1" />
                            Non verifie
                          </span>
                        )}
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(selectedDriver.status)}`}>
                          {selectedDriver.status}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Upload d&apos;image - seulement en mode edit */}
                  {modalType === 'edit' && (
                    <div className="bg-gray-50 p-4 rounded-lg">
                      <h3 className="text-lg font-semibold mb-4">Modifier la photo de profil</h3>
                      <div className="space-y-4">
                        {selectedDriverImageUrl && (
                          <div className="relative w-full h-48 rounded-lg overflow-hidden bg-gray-100 border-2 border-gray-200">
                            <img
                              src={selectedDriverImageUrl}
                              alt="Preview"
                              className="w-full h-full object-cover"
                            />
                            <button
                              type="button"
                              onClick={removeEditImage}
                              className="absolute top-2 right-2 p-2 bg-red-500 text-white rounded-full hover:bg-red-600 transition-colors shadow-lg"
                            >
                              <X className="w-4 h-4" />
                            </button>
                          </div>
                        )}

                        <div className="flex gap-3">
                          <label className="flex-1 cursor-pointer">
                            <div className="flex items-center justify-center gap-2 px-4 py-3 border-2 border-dashed border-gray-300 rounded-lg hover:border-blue-500 hover:bg-blue-50 transition-colors">
                              {editUploadingImage ? (
                                <>
                                  <div className="animate-spin rounded-full h-5 w-5 border-2 border-gray-300 border-t-blue-600"></div>
                                  <span className="text-sm text-gray-600">
                                    Upload en cours...
                                  </span>
                                </>
                              ) : (
                                <>
                                  <svg
                                    className="w-5 h-5 text-gray-600"
                                    fill="none"
                                    stroke="currentColor"
                                    viewBox="0 0 24 24"
                                  >
                                    <path
                                      strokeLinecap="round"
                                      strokeLinejoin="round"
                                      strokeWidth="2"
                                      d="M12 4v16m8-8H4"
                                    />
                                  </svg>
                                  <span className="text-sm text-gray-600">
                                    {editImagePreview || editFormData.profile_image_url
                                      ? 'Changer l\'image'
                                      : 'Telecharger une image'}
                                  </span>
                                </>
                              )}
                            </div>
                            <input
                              type="file"
                              accept="image/*"
                              onChange={handleEditImageUpload}
                              className="hidden"
                              disabled={editUploadingImage}
                            />
                          </label>

                          {/* Manual URL Input */}
                          <button
                            type="button"
                            onClick={() => {
                              const url = prompt("Entrez l'URL de l'image:");
                              if (url) {
                                setEditFormData({...editFormData, profile_image_url: url});
                                setEditImagePreview(null);
                              }
                            }}
                            className="px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                            title="Entrer une URL manuellement"
                          >
                            <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                            </svg>
                          </button>
                        </div>

                        <p className="text-xs text-gray-500">
                          Formats acceptes: JPG, PNG, GIF. Taille max: 5 MB
                        </p>
                      </div>
                    </div>
                  )}

                  {/* Informations */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Prenom
                      </label>
                      <input
                        type="text"
                        value={
                          modalType === 'edit'
                            ? editFormData.first_name ?? ''
                            : selectedDriver.first_name
                        }
                        onChange={(e) =>
                          handleInputChange('first_name', e.target.value)
                        }
                        disabled={modalType === 'view'}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent disabled:bg-gray-50 disabled:text-gray-500 ${
                          modalType === 'edit' && editFormErrors.first_name 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                      />
                      {modalType === 'edit' && editFormErrors.first_name && (
                        <p className="text-red-500 text-xs mt-1">{editFormErrors.first_name}</p>
                      )}
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Nom
                      </label>
                      <input
                        type="text"
                        value={
                          modalType === 'edit'
                            ? editFormData.last_name ?? ''
                            : selectedDriver.last_name
                        }
                        onChange={(e) =>
                          handleInputChange('last_name', e.target.value)
                        }
                        disabled={modalType === 'view'}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent disabled:bg-gray-50 disabled:text-gray-500 ${
                          modalType === 'edit' && editFormErrors.last_name 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                      />
                      {modalType === 'edit' && editFormErrors.last_name && (
                        <p className="text-red-500 text-xs mt-1">{editFormErrors.last_name}</p>
                      )}
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Telephone
                      </label>
                      <input
                        type="tel"
                        value={
                          modalType === 'edit'
                            ? editFormData.phone ?? ''
                            : selectedDriver.phone
                        }
                        onChange={(e) =>
                          handleInputChange('phone', e.target.value)
                        }
                        disabled={modalType === 'view'}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent disabled:bg-gray-50 disabled:text-gray-500 ${
                          modalType === 'edit' && editFormErrors.phone 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                      />
                      {modalType === 'edit' && editFormErrors.phone && (
                        <p className="text-red-500 text-xs mt-1">{editFormErrors.phone}</p>
                      )}
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Email
                      </label>
                      <input
                        type="email"
                        value={
                          modalType === 'edit'
                            ? editFormData.email ?? ''
                            : selectedDriver.email ?? ''
                        }
                        onChange={(e) =>
                          handleInputChange('email', e.target.value)
                        }
                        disabled={modalType === 'view'}
                        className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent disabled:bg-gray-50 disabled:text-gray-500 ${
                          modalType === 'edit' && editFormErrors.email 
                            ? 'border-red-300 focus:ring-red-500' 
                            : 'border-gray-300 focus:ring-blue-500'
                        }`}
                      />
                      {modalType === 'edit' && editFormErrors.email && (
                        <p className="text-red-500 text-xs mt-1">{editFormErrors.email}</p>
                      )}
                    </div>
                    {modalType === 'edit' && (
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Mot de passe
                        </label>
                        <input
                          type="password"
                          value={editFormData.password ?? ''}
                          onChange={(e) =>
                            handleInputChange('password', e.target.value)
                          }
                          placeholder="Laisser vide pour ne pas changer"
                          className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent ${
                            editFormErrors.password
                              ? 'border-red-300 focus:ring-red-500'
                              : 'border-gray-300 focus:ring-blue-500'
                          }`}
                        />
                        {editFormErrors.password ? (
                          <p className="text-red-500 text-xs mt-1">{editFormErrors.password}</p>
                        ) : (
                          <p className="text-xs text-gray-500 mt-1">Optionnel, minimum 6 caracteres</p>
                        )}
                      </div>
                    )}

                    <div className="md:col-span-2">
                      <div className="flex items-center justify-between">
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Localisation (GPS)
                        </label>
                        {modalType === 'edit' && (
                          <button
                            type="button"
                            onClick={() => {
                              handleInputChange('location_latitude', '');
                              handleInputChange('location_longitude', '');
                            }}
                            className="text-xs text-gray-500 hover:text-gray-700 underline"
                          >
                            Effacer
                          </button>
                        )}
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                          <input
                            type="number"
                            step="0.000001"
                            min="-90"
                            max="90"
                            value={
                              modalType === 'edit'
                                ? editFormData.location_latitude ?? ''
                                : selectedDriverCoords
                                  ? String(selectedDriverCoords.latitude)
                                  : ''
                            }
                            onChange={(e) => handleInputChange('location_latitude', e.target.value)}
                            disabled={modalType === 'view'}
                            placeholder="Latitude"
                            className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent disabled:bg-gray-50 disabled:text-gray-500 ${
                              modalType === 'edit' && editFormErrors.location_latitude
                                ? 'border-red-300 focus:ring-red-500'
                                : 'border-gray-300 focus:ring-blue-500'
                            }`}
                          />
                          {modalType === 'edit' && editFormErrors.location_latitude && (
                            <p className="text-red-500 text-xs mt-1">{editFormErrors.location_latitude}</p>
                          )}
                        </div>
                        <div>
                          <input
                            type="number"
                            step="0.000001"
                            min="-180"
                            max="180"
                            value={
                              modalType === 'edit'
                                ? editFormData.location_longitude ?? ''
                                : selectedDriverCoords
                                  ? String(selectedDriverCoords.longitude)
                                  : ''
                            }
                            onChange={(e) => handleInputChange('location_longitude', e.target.value)}
                            disabled={modalType === 'view'}
                            placeholder="Longitude"
                            className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:border-transparent disabled:bg-gray-50 disabled:text-gray-500 ${
                              modalType === 'edit' && editFormErrors.location_longitude
                                ? 'border-red-300 focus:ring-red-500'
                                : 'border-gray-300 focus:ring-blue-500'
                            }`}
                          />
                          {modalType === 'edit' && editFormErrors.location_longitude && (
                            <p className="text-red-500 text-xs mt-1">{editFormErrors.location_longitude}</p>
                          )}
                        </div>
                      </div>

                      {modalType === 'view' && !selectedDriverCoords && (
                        <div className="mt-1 text-xs text-gray-500 flex items-center gap-1">
                          <MapPin className="w-3 h-3" />
                          Aucune localisation disponible
                        </div>
                      )}

                      {modalType === 'view' && selectedDriverCoords && (
                        <a
                          href={`https://www.google.com/maps?q=${selectedDriverCoords.latitude},${selectedDriverCoords.longitude}`}
                          target="_blank"
                          rel="noreferrer"
                          className="mt-1 inline-flex items-center gap-1 text-xs text-blue-600 hover:text-blue-800"
                        >
                          <MapPin className="w-3 h-3" />
                          Ouvrir dans Google Maps
                        </a>
                      )}
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Langue
                      </label>
                      <select
                        value={
                          modalType === 'edit'
                            ? (editFormData.locale ?? normalizeLocale(selectedDriver.locale))
                            : normalizeLocale(selectedDriver.locale)
                        }
                        onChange={(e) => handleInputChange('locale', e.target.value)}
                        disabled={modalType === 'view'}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:text-gray-500"
                      >
                        {LOCALE_OPTIONS.map((option) => (
                          <option key={option.value} value={option.value}>
                            {option.label}
                          </option>
                        ))}
                      </select>
                      {modalType === 'edit' && editFormErrors.locale && (
                        <p className="text-red-500 text-xs mt-1">{editFormErrors.locale}</p>
                      )}
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Type de vehicule
                      </label>
                      {modalType === 'edit' ? (
                        <select
                          value={editFormData.vehicle_type ?? selectedDriver.vehicle_type}
                          onChange={(e) =>
                            handleInputChange('vehicle_type', e.target.value)
                          }
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                        >
                          <option value="motorcycle">Moto</option>
                          <option value="bicycle">Velo</option>
                          <option value="scooter">Scooter</option>
                        </select>
                      ) : (
                        <input
                          type="text"
                          value={selectedDriver.vehicle_type}
                          disabled
                          className="w-full px-3 py-2 border border-gray-300 rounded-lg disabled:bg-gray-50 disabled:text-gray-500 capitalize"
                        />
                      )}
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Plaque d&apos;immatriculation
                      </label>
                      <input
                        type="text"
                        value={
                          modalType === 'edit'
                            ? editFormData.vehicle_plate ?? ''
                            : selectedDriver.vehicle_plate ?? ''
                        }
                        onChange={(e) =>
                          handleInputChange('vehicle_plate', e.target.value)
                        }
                        disabled={modalType === 'view'}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:text-gray-500"
                      />
                    </div>
                    <div className="md:col-span-2">
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        Numero de permis
                      </label>
                      <input
                        type="text"
                        value={
                          modalType === 'edit'
                            ? editFormData.license_number ?? ''
                            : selectedDriver.license_number ?? ''
                        }
                        onChange={(e) =>
                          handleInputChange('license_number', e.target.value)
                        }
                        disabled={modalType === 'view'}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-50 disabled:text-gray-500"
                      />
                    </div>
                    
                    {modalType === 'edit' && (
                      <>
                        <div>
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Statut
                          </label>
                          <select
                            value={editFormData.status ?? selectedDriver.status}
                            onChange={(e) =>
                              handleInputChange('status', e.target.value)
                            }
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                          >
                            <option value="available">Disponible</option>
                            <option value="busy">Occupe</option>
                            <option value="offline">Hors ligne</option>
                            <option value="suspended">Suspendu</option>
                          </select>
                        </div>

                        <div className="flex items-center gap-4 pt-6">
                          <label className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              checked={!!editFormData.is_verified}
                              onChange={(e) =>
                                handleInputChange('is_verified', e.target.checked)
                              }
                              className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                            />
                            <span className="text-sm font-medium text-gray-700">
                              Verifie
                            </span>
                          </label>
                          <label className="flex items-center gap-2">
                            <input
                              type="checkbox"
                              checked={!!editFormData.is_active}
                              onChange={(e) =>
                                handleInputChange('is_active', e.target.checked)
                              }
                              className="w-4 h-4 text-blue-600 rounded focus:ring-blue-500"
                            />
                            <span className="text-sm font-medium text-gray-700">
                              Actif
                            </span>
                          </label>
                        </div>

                        <div className="md:col-span-2">
                          <label className="block text-sm font-medium text-gray-700 mb-1">
                            Notes
                          </label>
                          <textarea
                            value={editFormData.notes ?? ''}
                            onChange={(e) =>
                              handleInputChange('notes', e.target.value)
                            }
                            rows={3}
                            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                            placeholder="Notes administratives..."
                          />
                        </div>
                      </>
                    )}
                  </div>

                  {/* Statistiques */}
                  <div className="grid grid-cols-4 gap-4 p-4 bg-gray-50 rounded-lg">
                    <div className="text-center">
                      <div className="flex items-center justify-center gap-1 text-2xl font-bold text-yellow-600">
                        <Star className="w-5 h-5" />
                        {selectedDriver.rating !== null &&
                        selectedDriver.rating !== undefined
                          ? parseFloat(String(selectedDriver.rating)).toFixed(1)
                          : '0.0'}
                      </div>
                      <div className="text-xs text-gray-600 mt-1">
                        Note moyenne
                      </div>
                    </div>
                    <div className="text-center">
                      <div className="flex items-center justify-center gap-1 text-2xl font-bold text-blue-600">
                        <TrendingUp className="w-5 h-5" />
                        {selectedDriver.total_deliveries}
                      </div>
                      <div className="text-xs text-gray-600 mt-1">
                        Livraisons
                      </div>
                    </div>
                    <div className="text-center">
                      <div className="flex items-center justify-center gap-1 text-2xl font-bold text-green-600">
                        <Activity className="w-5 h-5" />
                        {selectedDriver.active_orders.length}/{selectedDriver.max_orders_capacity}
                      </div>
                      <div className="text-xs text-gray-600 mt-1">
                        Commandes actives
                      </div>
                    </div>
                    <div className="text-center">
                      <div className="flex items-center justify-center gap-1 text-2xl font-bold text-orange-600">
                        as i {selectedDriver.cancellation_count}
                      </div>
                      <div className="text-xs text-gray-600 mt-1">
                        Annulations
                      </div>
                    </div>
                  </div>

                  {/* Date d'inscription */}
                  <div className="text-center text-sm text-gray-500 border-t pt-4">
                    <div className="flex items-center justify-center gap-2">
                      <Calendar className="w-4 h-4" />
                      Inscrit depuis le {formatDate(selectedDriver.created_at)}
                    </div>
                    {selectedDriver.last_active_at && (
                      <div className="flex items-center justify-center gap-2 mt-1">
                        <Activity className="w-4 h-4" />
                        Derniere activite: {formatDate(selectedDriver.last_active_at)}
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Footer */}
            {modalType !== 'delete' && (
              <div className="px-6 py-4 border-t border-gray-200 flex justify-end gap-3">
                <button
                  onClick={handleCloseModal}
                  disabled={saveLoading}
                  className="px-4 py-2 bg-gray-200 text-gray-800 rounded-lg hover:bg-gray-300 transition-colors disabled:opacity-50"
                >
                  {modalType === 'view' ? 'Fermer' : 'Annuler'}
                </button>
                {modalType === 'edit' && (
                  <button
                    onClick={handleSave}
                    disabled={saveLoading || editUploadingImage}
                    className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 flex items-center gap-2"
                  >
                    {saveLoading ? (
                      <>
                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                        Enregistrement...
                      </>
                    ) : (
                      <>
                        <Save className="w-4 h-4" />
                        Enregistrer
                      </>
                    )}
                  </button>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}












