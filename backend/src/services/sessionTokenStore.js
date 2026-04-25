const refreshTokens = new Map();

export const storeRefreshToken = (refreshToken, data) => {
  if (!refreshToken) return null;
  refreshTokens.set(refreshToken, data);
  return refreshToken;
};

export const getRefreshTokenData = (refreshToken) => {
  if (!refreshToken) return null;
  return refreshTokens.get(refreshToken) || null;
};

export const revokeRefreshToken = (refreshToken) => {
  if (!refreshToken) return false;
  return refreshTokens.delete(refreshToken);
};

export const revokeRefreshTokensForUser = (userId) => {
  if (!userId) return 0;

  let revokedCount = 0;
  for (const [token, tokenData] of refreshTokens.entries()) {
    if (tokenData?.userId === userId) {
      refreshTokens.delete(token);
      revokedCount += 1;
    }
  }

  return revokedCount;
};

