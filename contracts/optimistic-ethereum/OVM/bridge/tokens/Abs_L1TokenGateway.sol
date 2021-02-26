// SPDX-License-Identifier: MIT
// @unsupported: ovm 
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Interface Imports */
import { iOVM_L1TokenGateway } from "../../../iOVM/bridge/tokens/iOVM_L1TokenGateway.sol";
import { iOVM_L2DepositedERC20 } from "../../../iOVM/bridge/tokens/iOVM_L2DepositedERC20.sol";
import { iOVM_ERC20 } from "../../../iOVM/precompiles/iOVM_ERC20.sol";

/* Library Imports */
import { OVM_CrossDomainEnabled } from "../../../libraries/bridge/OVM_CrossDomainEnabled.sol";

abstract contract Abs_L1TokenGateway is iOVM_L1TokenGateway, OVM_CrossDomainEnabled {
    
    function _handleFinalizeWithdrawal(
        address _to,
        uint256 _amount
    )
        internal
        virtual
    {
        revert("Implement me in child contracts");
    }

    function _handleInitiateDeposit(
        address _from,
        address _to,
        uint256 _amount
    )
        internal
        virtual
    {
        revert("Implement me in child contracts");
    }

    /********************************
     * External Contract References *
     ********************************/

    address public l2DepositedERC20;

    /***************
     * Constructor *
     ***************/

    /**
     * @param _l2DepositedERC20 L2 Gateway address on the chain being deposited into
     * @param _l1messenger L1 Messenger address being used for cross-chain communications.
     */
    constructor(
        address _l2DepositedERC20,
        address _l1messenger 
    )
        OVM_CrossDomainEnabled(_l1messenger)
    {
        l2DepositedERC20 = _l2DepositedERC20;
    }

    /**************
     * Depositing *
     **************/

    /**
     * @dev deposit an amount of the ERC20 to the caller's balance on L2
     * @param _amount Amount of the ERC20 to deposit
     */
    function deposit(
        uint _amount
    )
        public
        override
    {
        _initiateDeposit(msg.sender, msg.sender, _amount);
    }

    /**
     * @dev deposit an amount of ERC20 to a recipients's balance on L2
     * @param _to L2 address to credit the withdrawal to
     * @param _amount Amount of the ERC20 to deposit
     */
    function depositTo(
        address _to,
        uint _amount
    )
        public
        override
    {
        _initiateDeposit(msg.sender, _to, _amount);
    }

    /**
     * @dev Performs the logic for deposits by storing the ERC20 and informing the L2 Deposited ERC20 contract of the deposit.
     *
     * @param _from Account to pull the deposit from on L1
     * @param _to Account to give the deposit to on L2
     * @param _amount Amount of the ERC20 to deposit.
     */
    function _initiateDeposit(
        address _from,
        address _to,
        uint _amount
    )
        internal
    {
        _handleInitiateDeposit(
            _from,
            _to,
            _amount
        );

        // Construct calldata for l2DepositedERC20.finalizeDeposit(_to, _amount)
        bytes memory data = abi.encodeWithSelector(
            iOVM_L2DepositedERC20.finalizeDeposit.selector,
            _to,
            _amount
        );

        // Send calldata into L2
        sendCrossDomainMessage(
            l2DepositedERC20,
            data,
            DEFAULT_FINALIZE_DEPOSIT_L2_GAS
        );

        emit DepositInitiated(_from, _to, _amount);
    }

    /*************************************
     * Cross-chain Function: Withdrawing *
     *************************************/

    /**
     * @dev Complete a withdrawal from L2 to L1, and credit funds to the recipient's balance of the 
     * L1 ERC20 token. 
     * This call will fail if the initialized withdrawal from L2 has not been finalized. 
     *
     * @param _to L1 address to credit the withdrawal to
     * @param _amount Amount of the ERC20 to withdraw
     */
    function finalizeWithdrawal(
        address _to,
        uint _amount
    )
        external
        override 
        onlyFromCrossDomainAccount(l2DepositedERC20)
    {
        _handleFinalizeWithdrawal(
            _to,
            _amount
        );

        emit WithdrawalFinalized(_to, _amount);
    }
}
