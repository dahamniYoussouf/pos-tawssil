import * as geoService from "../services/geo.service.js";

export const getWilayas = async (req, res, next) => {
  try {
    const data = await geoService.listWilayas();
    res.json({
      success: true,
      count: data.length,
      data
    });
  } catch (err) {
    next(err);
  }
};

export const getCommunes = async (req, res, next) => {
  try {
    const { wilaya_code } = req.query;
    if (!wilaya_code) {
      return res.status(400).json({
        success: false,
        message: "wilaya_code is required"
      });
    }

    const data = await geoService.listCommunes({ wilaya_code });
    res.json({
      success: true,
      count: data.length,
      data
    });
  } catch (err) {
    next(err);
  }
};

export const getCommune = async (req, res, next) => {
  try {
    const data = await geoService.getCommuneById(req.params.id);
    res.json({
      success: true,
      data
    });
  } catch (err) {
    next(err);
  }
};

export const createWilaya = async (req, res, next) => {
  try {
    const data = await geoService.createWilaya(req.body);
    res.status(201).json({
      success: true,
      data
    });
  } catch (err) {
    next(err);
  }
};

export const updateWilaya = async (req, res, next) => {
  try {
    const data = await geoService.updateWilaya(req.params.code, req.body);
    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Wilaya not found"
      });
    }
    res.json({
      success: true,
      data
    });
  } catch (err) {
    next(err);
  }
};

export const deleteWilaya = async (req, res, next) => {
  try {
    const deleted = await geoService.deleteWilaya(req.params.code);
    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Wilaya not found"
      });
    }
    res.json({
      success: true,
      message: "Wilaya deleted successfully"
    });
  } catch (err) {
    next(err);
  }
};

export const createCommune = async (req, res, next) => {
  try {
    const data = await geoService.createCommune(req.body);
    res.status(201).json({
      success: true,
      data
    });
  } catch (err) {
    next(err);
  }
};

export const updateCommune = async (req, res, next) => {
  try {
    const data = await geoService.updateCommune(req.params.id, req.body);
    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Commune not found"
      });
    }
    res.json({
      success: true,
      data
    });
  } catch (err) {
    next(err);
  }
};

export const deleteCommune = async (req, res, next) => {
  try {
    const deleted = await geoService.deleteCommune(req.params.id);
    if (!deleted) {
      return res.status(404).json({
        success: false,
        message: "Commune not found"
      });
    }
    res.json({
      success: true,
      message: "Commune deleted successfully"
    });
  } catch (err) {
    next(err);
  }
};
