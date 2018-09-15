import { BigNumber } from 'bignumber.js';

export const DEFAULT_GAS_LIMIT: BigNumber = new BigNumber(6712390); // Default of 6.7 million gas
export const DEFAULT_GAS_PRICE: BigNumber = new BigNumber(6000000000); // 6 gEei
export const UNLIMITED_ALLOWANCE_IN_BASE_UNITS: BigNumber = new BigNumber(2).pow(256).minus(1);
export const STANDARD_DECIMALS: BigNumber = new BigNumber(18); // ETH natural unit, wei
export const ZERO: BigNumber = new BigNumber(0);

export const EXECUTOR_CACHE_KEY = 'Executor';
export const REGISTRY_CACHE_KEY = 'Registry';
export const PAYMENT_REGISTRY_CACHE_KEY = 'PaymentRegistry';
export const VOLUME_SUBSCRIPTION_CACHE_KEY = 'VolumeSubscription';
export const STAKE_CONTRACT_CACHE_KEY = 'StakeContract';
export const REQUIREMENTS_CACHE_KEY = 'Requirements';

export function TX_DEFAULTS(from: string) {
  return {
    from: from,
    gasPrice: DEFAULT_GAS_PRICE,
    gas: DEFAULT_GAS_LIMIT
  }
};

