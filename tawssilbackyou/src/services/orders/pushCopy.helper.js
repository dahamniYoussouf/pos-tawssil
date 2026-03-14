const buildLocalizedNotification = ({
  titleFr,
  bodyFr,
  titleEn = titleFr,
  bodyEn = bodyFr,
  titleAr = titleFr,
  bodyAr = bodyFr
}) => ({
  title: titleFr,
  message: bodyFr,
  i18n: {
    fr: { title: titleFr, body: bodyFr },
    en: { title: titleEn, body: bodyEn },
    ar: { title: titleAr, body: bodyAr }
  }
});

export const getClientAcceptedCopy = (orderType) => {
  if (orderType === "pickup") {
    return buildLocalizedNotification({
      titleFr: "🍽️ Commande confirmee",
      bodyFr: "Le restaurant a confirme votre commande. Elle sera preparee dans quelques instants.",
      titleEn: "🍽️ Order confirmed",
      bodyEn: "The restaurant confirmed your order. It will be prepared shortly.",
      titleAr: "🍽️ Commande confirmee",
      bodyAr: "Le restaurant a confirme votre commande. Elle sera preparee dans quelques instants."
    });
  }

  return buildLocalizedNotification({
    titleFr: "🍽️ Commande confirmee",
    bodyFr: "Bonne nouvelle, le restaurant a confirme votre commande et lance la preparation.",
    titleEn: "🍽️ Order confirmed",
    bodyEn: "Good news, the restaurant confirmed your order and started preparing it.",
    titleAr: "🍽️ Commande confirmee",
    bodyAr: "Bonne nouvelle, le restaurant a confirme votre commande et lance la preparation."
  });
};

export const getClientOrderCreatedCopy = () =>
  buildLocalizedNotification({
    titleFr: "🍔 Commande recue",
    bodyFr: "Votre commande a bien ete transmise au restaurant.",
    titleEn: "🍔 Order received",
    bodyEn: "Your order was sent to the restaurant.",
    titleAr: "🍔 Commande recue",
    bodyAr: "Votre commande a bien ete transmise au restaurant."
  });

export const getClientPreparingCopy = () =>
  buildLocalizedNotification({
    titleFr: "🍳 Preparation en cours",
    bodyFr: "Le restaurant prepare actuellement votre commande.",
    titleEn: "🍳 Preparing your order",
    bodyEn: "The restaurant is currently preparing your order.",
    titleAr: "🍳 Preparation en cours",
    bodyAr: "Le restaurant prepare actuellement votre commande."
  });

export const getClientDeliveryStartedCopy = () =>
  buildLocalizedNotification({
    titleFr: "🛵 Livraison en route",
    bodyFr: "Le livreur a recupere votre repas et roule vers vous.",
    titleEn: "🛵 Delivery on the way",
    bodyEn: "The driver picked up your meal and is heading to you.",
    titleAr: "🛵 Livraison en route",
    bodyAr: "Le livreur a recupere votre repas et roule vers vous."
  });

export const getClientDriverAssignedCopy = () =>
  buildLocalizedNotification({
    titleFr: "🛵 Livreur assigne",
    bodyFr: "Un livreur a ete assigne a votre commande.",
    titleEn: "🛵 Driver assigned",
    bodyEn: "A driver has been assigned to your order.",
    titleAr: "🛵 Livreur assigne",
    bodyAr: "Un livreur a ete assigne a votre commande."
  });

export const getClientDriverNearbyCopy = () =>
  buildLocalizedNotification({
    titleFr: "🛵 Votre livreur est tout proche",
    bodyFr: "Le livreur est a moins de 50 metres. Preparez-vous a recevoir votre repas.",
    titleEn: "🛵 Your driver is very close",
    bodyEn: "The driver is within 50 meters. Get ready to receive your meal.",
    titleAr: "🛵 Votre livreur est tout proche",
    bodyAr: "Le livreur est a moins de 50 metres. Preparez-vous a recevoir votre repas."
  });

export const getClientDeliveredCopy = () =>
  buildLocalizedNotification({
    titleFr: "🍽️ Repas livre",
    bodyFr: "Votre repas a bien ete livre. Bon appetit avec Tawsil.",
    titleEn: "🍽️ Meal delivered",
    bodyEn: "Your meal was delivered successfully. Enjoy your meal with Tawsil.",
    titleAr: "🍽️ Repas livre",
    bodyAr: "Votre repas a bien ete livre. Bon appetit avec Tawsil."
  });

export const getClientDeclinedCopy = () =>
  buildLocalizedNotification({
    titleFr: "🍽️ Commande refusee",
    bodyFr: "Votre commande n'a pas ete acceptee par le restaurant. Aucun montant ne sera debite.",
    titleEn: "🍽️ Order declined",
    bodyEn: "Your order was not accepted by the restaurant. No amount will be charged.",
    titleAr: "🍽️ Commande refusee",
    bodyAr: "Votre commande n'a pas ete acceptee par le restaurant. Aucun montant ne sera debite."
  });

export const getClientDeliveryCancelledCopy = () =>
  buildLocalizedNotification({
    titleFr: "🛵 Nouveau livreur en recherche",
    bodyFr: "Votre livreur a annule la livraison. Nous cherchons un autre livreur pour finaliser votre repas.",
    titleEn: "🛵 Looking for a new driver",
    bodyEn: "Your driver cancelled the delivery. We are looking for another driver to complete your meal.",
    titleAr: "🛵 Nouveau livreur en recherche",
    bodyAr: "Votre livreur a annule la livraison. Nous cherchons un autre livreur pour finaliser votre repas."
  });

export const getClientReadyForPickupCopy = () =>
  buildLocalizedNotification({
    titleFr: "🍱 Commande prete",
    bodyFr: "Votre commande est prete. Vous pouvez venir recuperer votre repas au restaurant.",
    titleEn: "🍱 Order ready",
    bodyEn: "Your order is ready. You can collect your meal at the restaurant.",
    titleAr: "🍱 Commande prete",
    bodyAr: "Votre commande est prete. Vous pouvez venir recuperer votre repas au restaurant."
  });

export const getClientOrderLocationCopy = ({ distanceKm = null, etaMin = null, etaMax = null } = {}) => {
  const hasEtaRange = Number.isFinite(etaMin) && Number.isFinite(etaMax);
  const hasDistance = Number.isFinite(distanceKm);

  if (hasDistance && hasEtaRange) {
    return buildLocalizedNotification({
      titleFr: "🛵 Livraison proche",
      bodyFr: `Votre repas est a ${distanceKm} km et arrive dans environ ${etaMin}-${etaMax} min.`,
      titleEn: "🛵 Delivery nearby",
      bodyEn: `Your meal is ${distanceKm} km away and should arrive in about ${etaMin}-${etaMax} min.`,
      titleAr: "🛵 Livraison proche",
      bodyAr: `Votre repas est a ${distanceKm} km et arrive dans environ ${etaMin}-${etaMax} min.`
    });
  }

  return buildLocalizedNotification({
    titleFr: "🛵 Suivi livraison",
    bodyFr: "Votre repas est en route vers vous.",
    titleEn: "🛵 Delivery tracking",
    bodyEn: "Your meal is on the way to you.",
    titleAr: "🛵 Suivi livraison",
    bodyAr: "Votre repas est en route vers vous."
  });
};

export const getRestaurantNewOrderCopy = (orderType) => {
  if (orderType === "delivery") {
    return buildLocalizedNotification({
      titleFr: "🛵 Nouvelle commande en livraison",
      bodyFr: "Vous avez recu une nouvelle commande repas a preparer pour livraison.",
      titleEn: "🛵 New delivery order",
      bodyEn: "You received a new meal order to prepare for delivery.",
      titleAr: "🛵 Nouvelle commande en livraison",
      bodyAr: "Vous avez recu une nouvelle commande repas a preparer pour livraison."
    });
  }

  return buildLocalizedNotification({
    titleFr: "🍱 Nouvelle commande pickup",
    bodyFr: "Vous avez recu une nouvelle commande repas a preparer.",
    titleEn: "🍱 New pickup order",
    bodyEn: "You received a new meal order to prepare for pickup.",
    titleAr: "🍱 Nouvelle commande pickup",
    bodyAr: "Vous avez recu une nouvelle commande repas a preparer."
  });
};

export const getDriverNewMissionCopy = () =>
  buildLocalizedNotification({
    titleFr: "🛵 Nouvelle mission livraison",
    bodyFr: "Une nouvelle course repas est disponible. Consultez les details et acceptez-la rapidement.",
    titleEn: "🛵 New delivery mission",
    bodyEn: "A new meal delivery mission is available. Check the details and accept it quickly.",
    titleAr: "🛵 Nouvelle mission livraison",
    bodyAr: "Une nouvelle course repas est disponible. Consultez les details et acceptez-la rapidement."
  });

export const getDriverDeliveryCompleteCopy = (activeOrdersCount = 0) => {
  const remainingCount = Number.isFinite(Number(activeOrdersCount)) ? Number(activeOrdersCount) : 0;

  if (remainingCount > 0) {
    return buildLocalizedNotification({
      titleFr: "🛵 Livraison terminee",
      bodyFr: `Livraison terminee avec succes. Il vous reste ${remainingCount} commande(s) active(s).`,
      titleEn: "🛵 Delivery completed",
      bodyEn: `Delivery completed successfully. You still have ${remainingCount} active order(s).`,
      titleAr: "🛵 Livraison terminee",
      bodyAr: `Livraison terminee avec succes. Il vous reste ${remainingCount} commande(s) active(s).`
    });
  }

  return buildLocalizedNotification({
    titleFr: "🛵 Livraison terminee",
    bodyFr: "Livraison terminee avec succes. Vous etes de nouveau disponible.",
    titleEn: "🛵 Delivery completed",
    bodyEn: "Delivery completed successfully. You are available again.",
    titleAr: "🛵 Livraison terminee",
    bodyAr: "Livraison terminee avec succes. Vous etes de nouveau disponible."
  });
};
