// SPDX-License-Identifier: MIT
import "./IStargateRouter.sol";

pragma solidity ^0.8.4;
pragma abicoder v2;

interface IStargateRouterETH {
    struct SwapAmount {
        uint256 amountLD; // the amount, in Local Decimals, to be swapped
        uint256 minAmountLD; // the minimum amount accepted out on destination
    }

    function addLiquidityETH() external payable;

    function swapETH(
        uint16 dstChainId,
        address payable refundAddress,
        bytes calldata to,
        uint256 amountLD,
        uint256 minAmountLD
    ) external payable;

    function swapETHAndCall(
        uint16 _dstChainId, // destination Stargate chainId
        address payable _refundAddress, // refund additional messageFee to this address
        bytes calldata _toAddress, // the receiver of the destination ETH
        SwapAmount memory _swapAmount, // the amount and the minimum swap amount
        IStargateRouter.lzTxObj memory _lzTxParams, // the LZ tx params
        bytes calldata _payload // the payload to send to the destination
    ) external payable;

}
