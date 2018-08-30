/* GENERATED BY TYPECHAIN VER. 0.2.7 */
/* tslint:disable */

import { BigNumber } from "bignumber.js";
import * as TC from "./typechain-runtime";

export class ActionProxy extends TC.TypeChainContract {
  public readonly rawWeb3Contract: any;

  public constructor(web3: any, address: string | BigNumber) {
    const abi = [
      {
        constant: false,
        inputs: [
          { name: "_subscriptionContract", type: "address" },
          { name: "_planIdentifier", type: "bytes32" }
        ],
        name: "newAddress",
        outputs: [{ name: "_subscriptionIdentifier", type: "bytes32" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: false,
        inputs: [
          { name: "_subscriptionContract", type: "address" },
          { name: "_planIdentifier", type: "bytes32" }
        ],
        name: "existingAddress",
        outputs: [{ name: "_subscriptionIdentifier", type: "bytes32" }],
        payable: false,
        stateMutability: "nonpayable",
        type: "function"
      },
      {
        constant: true,
        inputs: [
          { name: "_subscriptionContract", type: "address" },
          { name: "_subscriptionIdentifier", type: "bytes32" }
        ],
        name: "returnState",
        outputs: [
          { name: "", type: "uint8" },
          { name: "timeLeft", type: "uint256" }
        ],
        payable: false,
        stateMutability: "view",
        type: "function"
      }
    ];
    super(web3, address, abi);
  }

  static async createAndValidate(
    web3: any,
    address: string | BigNumber
  ): Promise<ActionProxy> {
    const contract = new ActionProxy(web3, address);
    const code = await TC.promisify(web3.eth.getCode, [address]);

    // in case of missing smartcontract, code can be equal to "0x0" or "0x" depending on exact web3 implementation
    // to cover all these cases we just check against the source code length — there won't be any meaningful EVM program in less then 3 chars
    if (code.length < 4) {
      throw new Error(`Contract at ${address} doesn't exist!`);
    }
    return contract;
  }

  public returnState(
    _subscriptionContract: BigNumber | string,
    _subscriptionIdentifier: string
  ): Promise<[BigNumber, BigNumber]> {
    return TC.promisify(this.rawWeb3Contract.returnState, [
      _subscriptionContract.toString(),
      _subscriptionIdentifier.toString()
    ]);
  }

  public newAddressTx(
    _subscriptionContract: BigNumber | string,
    _planIdentifier: string
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(this, "newAddress", [
      _subscriptionContract.toString(),
      _planIdentifier.toString()
    ]);
  }
  public existingAddressTx(
    _subscriptionContract: BigNumber | string,
    _planIdentifier: string
  ): TC.DeferredTransactionWrapper<TC.ITxParams> {
    return new TC.DeferredTransactionWrapper<TC.ITxParams>(
      this,
      "existingAddress",
      [_subscriptionContract.toString(), _planIdentifier.toString()]
    );
  }
}
