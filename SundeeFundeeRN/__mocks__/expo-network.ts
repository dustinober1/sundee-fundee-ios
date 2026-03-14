/**
 * Mock for expo-network.
 *
 * Provides Jest stubs for network state queries.
 * Defaults to "online" (isConnected: true, isInternetReachable: true).
 */

export const NetworkStateType = {
  NONE: 'NONE',
  UNKNOWN: 'UNKNOWN',
  CELLULAR: 'CELLULAR',
  WIFI: 'WIFI',
  BLUETOOTH: 'BLUETOOTH',
  ETHERNET: 'ETHERNET',
  WIMAX: 'WIMAX',
  VPN: 'VPN',
  OTHER: 'OTHER',
} as const;

export const getNetworkStateAsync = jest.fn().mockResolvedValue({
  type: NetworkStateType.WIFI,
  isConnected: true,
  isInternetReachable: true,
});

export const getIpAddressAsync = jest.fn().mockResolvedValue('127.0.0.1');

export const isAirplaneModeEnabledAsync = jest.fn().mockResolvedValue(false);
