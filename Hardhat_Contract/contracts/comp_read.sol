// SPDX-License-Identifier: AGPL
pragma solidity ^0.8.9;
import "./compound/CErc20.sol";
import "./compound/Comptroller.sol";
import "./compound/Linkoracle.sol";
import "hardhat/console.sol";
contract comp_read{
    Comptroller public compound;
    Linkoracle public priceOracle;
    uint256 constant blocksPerYear = 2102400;

    struct init_info{
        address compound;
        address priceOracle;
    }
    constructor(init_info memory _info) {
        compound=Comptroller(_info.compound);
        priceOracle=Linkoracle(_info.priceOracle);
    }
    struct M_CToken{
        // string name;
        string symbol;
        uint256 decimals;
        address underlying;
        address CTokenadd;
        string cname;
        string csymbol;
        uint256 Total_Deposits;
        uint256 Total_Borrows;
        uint256 Deposit_APR;
        uint256 Borrow_APR;
    }
    struct s_Markets{
        uint256 e_price;
        M_CToken[] CTokens;
        uint256 Total_Market_Size;
        uint256 Total_Borrows;
        uint256 Total_Available;
    }
    function Markets()public view returns(
        s_Markets memory markets
    ) {
        uint256 total_borrows;
        uint256 total_available;
        uint256 total_market_size;
        CToken[] memory CTokens =compound.getAllMarkets();
        M_CToken[] memory M_CTokens= new M_CToken[](CTokens.length);
        for (uint256 i = 0; i < CTokens.length; i++) {
            CToken n_CToken = CTokens[i];
            uint256 price = priceOracle.getUnderlyingPrice(n_CToken);
            uint256 CToken_borrows=n_CToken.totalBorrows()*price/10**18;
            uint256 CToken_available=n_CToken.getCash()*price/10**18;
            uint256 Total_Deposits=CToken_borrows+CToken_available;
            address Token = priceOracle._getUnderlyingAddress(n_CToken);
            uint decimal=18;
            // string memory name ="ETH";
            string memory symbol ="ETH";
            if (Token!=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                decimal=CErc20(Token).decimals();
                // name=CErc20(Token).name();
                symbol=CErc20(Token).symbol();
            }else{
                markets.e_price=price/10**(18-decimal);
            }
            M_CTokens[i]=M_CToken(
                // name,
                symbol,
                decimal,
                priceOracle._getUnderlyingAddress(n_CToken),
                // CErc20(address(n_CToken)).underlying(),
                address(n_CToken),
                n_CToken.name(),
                n_CToken.symbol(),
                Total_Deposits,
                CToken_borrows,
                n_CToken.supplyRatePerBlock() *blocksPerYear/10**10,
                n_CToken.borrowRatePerBlock()*blocksPerYear/10**10
            );
            total_market_size+=Total_Deposits;
            total_borrows+=CToken_borrows;
            total_available+=CToken_available;
        }
        markets=s_Markets(
            markets.e_price,
            M_CTokens,
            total_market_size,
            total_borrows,
            total_available
        );
    }
    struct D_CToken{
        string symbol;
        uint256 decimals;
        address underlying;
        address CTokenadd;
        string cname;
        string csymbol;
        uint256 price;
        uint256 Deposits;
        uint256 Deposits_value;
        uint256 Deposit_APR;

        bool Collateral;

        uint256 Borrows;
        uint256 Borrows_value;
        uint256 Borrow_APR;

        uint256 balance;
        uint256 net_worth;
        uint256 max_withdraw;
        uint256 max_withdraw_ctoken;
        uint256 max_borrow;
        uint256 collateralFactor;
    }
    struct s_Dashboard{
        uint256 e_price;
        D_CToken[] CTokens;
        uint256 Total_Deposits;
        uint256 Total_Borrows;
        uint256 Health_Factor;
        uint256 liquidity;
        uint256 sumCollateral;
    }
    function Dashboard(address sender)public view returns(
        s_Dashboard memory dashboard
    ){
        uint256 Total_Deposits;
        uint256 Total_Borrows;
        CToken[] memory CTokens =compound.getAllMarkets();
        D_CToken[] memory D_CTokens= new D_CToken[](CTokens.length);
        (,uint256 liquidity,)=compound.getAccountLiquidity(sender);
        for (uint256 i = 0; i < CTokens.length; i++) {
            address n_sender = sender;
            CToken n_CToken = CTokens[i];
            address Token=priceOracle._getUnderlyingAddress(n_CToken);
            uint256 price = priceOracle.getUnderlyingPrice(n_CToken);
            D_CTokens[i].max_borrow=liquidity*10**18/price;
            uint256 t_amount = n_CToken.balanceOf(n_sender)*n_CToken.exchangeRateStored()/10**18;
            uint256 b_amount = n_CToken.borrowBalanceStored(n_sender);
            
            Total_Deposits+=(t_amount*price/10**18);
            Total_Borrows+=(b_amount*price/10**18);
            uint256 max_withdraw;
            uint256 max_withdraw_ctoken;
            D_CTokens[i].collateralFactor=compound.getcollateralFactor(n_CToken);
            if ((liquidity>=t_amount*price*D_CTokens[i].collateralFactor/10**36)||D_CTokens[i].collateralFactor==0||!compound.checkMembership(n_sender,n_CToken)) {
                max_withdraw=t_amount;
                max_withdraw_ctoken=n_CToken.balanceOf(n_sender);
            } else {
                max_withdraw=liquidity*10**36/(price*D_CTokens[i].collateralFactor)*99/100;
                max_withdraw_ctoken=max_withdraw*10**18/n_CToken.exchangeRateStored();
            }
            if (max_withdraw>n_CToken.getCash()) {
                max_withdraw=n_CToken.getCash();
                // max_withdraw_ctoken=max_withdraw*10**18/n_CToken.exchangeRateStored()*99/100;
                max_withdraw_ctoken=max_withdraw*10**18/n_CToken.exchangeRateStored()*99/100;
            }
            if(D_CTokens[i].max_borrow>n_CToken.getCash()){
                D_CTokens[i].max_borrow=n_CToken.getCash();
            }
            D_CTokens[i].decimals=18;
            D_CTokens[i].symbol ="ETH";
            if (Token!=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
                D_CTokens[i].decimals=CErc20(Token).decimals();
                D_CTokens[i].symbol=CErc20(Token).symbol();

            }else{
                dashboard.e_price=price/10**(18-D_CTokens[i].decimals);
            }
            D_CTokens[i]=D_CToken(
                // name,
                D_CTokens[i].symbol,
                D_CTokens[i].decimals,
                Token,
                address(n_CToken),
                n_CToken.name(),
                n_CToken.symbol(),
                price/10**(18-D_CTokens[i].decimals),
                t_amount,
                t_amount*price/10**18,
                n_CToken.supplyRatePerBlock() *blocksPerYear/10**10,

                compound.checkMembership(n_sender,n_CToken),

                b_amount,
                b_amount*price/10**18,
                n_CToken.borrowRatePerBlock()*blocksPerYear/10**10,

                n_CToken.balanceOf(n_sender),
                n_CToken.exchangeRateStored(),
                max_withdraw,
                max_withdraw_ctoken,
                D_CTokens[i].max_borrow,
                D_CTokens[i].collateralFactor/10**10
            );
        }
        uint256 Health_Factor=10**9;
        (,uint256 sumCollateral,uint256 sumBorrowPlusEffects)=compound.getHeakthFactor(sender);
        if (Total_Borrows!=0) {
            Health_Factor=sumCollateral*10**8/sumBorrowPlusEffects;
            if (Health_Factor> 10**9) {
                Health_Factor=10**9;
            }
        }
        dashboard=s_Dashboard(
            dashboard.e_price,
            D_CTokens,
            Total_Deposits,
            Total_Borrows,
            Health_Factor,
            liquidity,
            sumCollateral
        );
    }
    function getcusdaworth()public view returns(uint256 cusdaworth){
        CToken[] memory CTokens =compound.getAllMarkets();
        // D_CToken[] memory D_CTokens= new D_CToken[](CTokens.length);
        for (uint256 i = 0; i < CTokens.length; i++) {
            CToken n_CToken = CTokens[i];
            if (keccak256(abi.encode(n_CToken.symbol()))==keccak256(abi.encode("cUSDA"))) {
                return n_CToken.exchangeRateStored();
            }
        }
    }
}