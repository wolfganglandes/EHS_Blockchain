pragma solidity ^0.4.20;

contract EHS_Blockchain {
    
    struct Company {
        string name;   // Unique
        uint stillAllowed;  //How much tokenPrice are you still Allowed to buy.
        uint tokenBalance;
        uint greenInvestment;
        uint burned;
    }
    struct GreenEnergy {
        string name;  // Unique
        uint tokenBalance;
    }
    struct PrivatePerson {
        uint id;
        uint stillAllowed;
        uint tokenBalance;
    }
    
    //LISTS on Smart Contract as reference for Transaction.
    mapping (address => Company) public listCompanies;
    mapping (address => GreenEnergy) public listGreens;
    mapping (address => PrivatePerson) private listPrivatePeople;
    
    address public owner;

    //ATTRIBUTES Smart Contract updated after each transaction
    uint public expensiveTokenPrice = 3 ether;
    uint public tokenPrice = 1 ether;
    uint public circulationToken = 0;
    uint public withdrawPrice = 0; // Dynamic to this.balance / circulation;

    //Events for Frontend
    //event CheapCreditsBought(address buyer, uint amount);
    //event ExpensiveCreditsBought(address buyer, uint amount);

    //MODIFIER
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier onlyCompany(){
        require(keccak256(listCompanies[msg.sender].name) != 0);
        _;
    }
     modifier onlyRenewable(){
        require(keccak256(listGreens[msg.sender].name) != 0);
        _;
    }
    modifier onlyCompanyOrPrivatePerson(){
        require(( keccak256(listPrivatePeople[msg.sender].id) != 0)
        ||(keccak256(listCompanies[msg.sender].name) != 0));
        _;
    }
   
    //REGISTER Functions: Require owner == msg.sender
    function registerCompany(address a, string name, uint allowance) public onlyOwner {
        listCompanies[a] = Company(name, allowance, 0, 0, 0);
    }
    function registerPrivatePerson(uint id, address a, uint allowance) public onlyOwner{
        listPrivatePeople[a] = PrivatePerson(id, allowance, 0);
    }
     function registerRenewable(address a, string name) public onlyOwner{
        listGreens[a] = GreenEnergy(name, 0);
    }

     //CREATE SMART CONTRACT
    function EHS_Blockchain() public {
        owner = msg.sender;
    }
    
    //Money stored on Smart Contract
    function getMyBalance()view public returns (uint) { return this.balance; }
    
    //Burning Credits increases withdrawPrice
    function burnToken(uint amount)public onlyCompany{
        require(listCompanies[msg.sender].tokenBalance>=amount);
        
        listCompanies[msg.sender].tokenBalance -= amount;
        listCompanies[msg.sender].burned += amount;
        circulationToken -= amount;
        withdrawPrice = this.balance / circulationToken;
    }
    
    // Only listCompanies 
    // Can trade Token !!!
    // Regulator is Company, pay for Emission with this function
    // listGreens and PrivatePerson are not allowed to trade to avoid increasing the 
    // Pollution Cap
    function tradeToken(address company, uint amount) public onlyCompany{
        require(listCompanies[msg.sender].tokenBalance >= amount);
        
        listCompanies[msg.sender].tokenBalance -= amount;
        listCompanies[company].tokenBalance += amount;
    }
    
    // Companies and PrivatePerson are allowed to buy renewable Products with 
    // Token
    function buyGreenEnergy(address renew, uint amount) public onlyCompanyOrPrivatePerson{
        require(keccak256(listGreens[renew].name) != 0);
        
        if(listCompanies[msg.sender].tokenBalance >= amount){
            //listCompanies buy Renewable
            listCompanies[msg.sender].tokenBalance -= amount;
            listCompanies[msg.sender].greenInvestment += amount;
            listGreens[renew].tokenBalance += amount;
            }else if(listPrivatePeople[msg.sender].tokenBalance >= amount){
            //Private Person buy Renewable
            listPrivatePeople[msg.sender].tokenBalance -= amount;
            listGreens[renew].tokenBalance += amount;
            }
    }
    
    /*Only GreenEnergy 
    is allowed to return Credits and get Paid for it
    withdrawPrice == Money on Smart Contract / circulationToken
    The more Credits get burned the higher the withdrawPrice
    The more listCompanies have to pay expensiveTokenPrice for Credits 
    the higher the withdrawPrice*/
    
    //TODO:   MAYBE REFUND
    function burnTokenAndWithdraw(uint amount)public onlyRenewable{
        require(listGreens[msg.sender].tokenBalance>=amount);
        
        listGreens[msg.sender].tokenBalance -=amount;
        msg.sender.transfer(amount*withdrawPrice);
        circulationToken -= amount;
     }
    
   
    // ONLY COMPANY or PrivatePerson
    // Buy Credits for tokenPrice as much as you are allowed
    // After that buy Credits for expensiveTokenPrice depending on msg.value
    function buyToken() payable public onlyCompanyOrPrivatePerson {
        if(keccak256(listCompanies[msg.sender].name) != 0){
            //Company buing Credits
             if(msg.value <= listCompanies[msg.sender].stillAllowed * tokenPrice){
            //Only Cheap price
                uint creditsBoughtCheap = msg.value / tokenPrice;
                listCompanies[msg.sender].stillAllowed -= creditsBoughtCheap;
                listCompanies[msg.sender].tokenBalance += creditsBoughtCheap;
                circulationToken += creditsBoughtCheap;
                withdrawPrice = this.balance / circulationToken;
        
                return;
            }else{
                // Credits for Cheap + Credits for Expensive 
                uint input = msg.value;
                input -= listCompanies[msg.sender].stillAllowed * tokenPrice;
                uint maxCheap = listCompanies[msg.sender].stillAllowed;
                listCompanies[msg.sender].stillAllowed -= maxCheap;
                listCompanies[msg.sender].tokenBalance += maxCheap;
                circulationToken += maxCheap;
            
                uint creditsBoughtExp = input / expensiveTokenPrice;
                listCompanies[msg.sender].tokenBalance += creditsBoughtExp;
                circulationToken += creditsBoughtExp;
                withdrawPrice = this.balance / circulationToken;
            }
        }else{
            //Private buying Credits
            if(msg.value <= listPrivatePeople[msg.sender].stillAllowed * tokenPrice){
            //Only Cheap price
                creditsBoughtCheap = msg.value / tokenPrice;
                listPrivatePeople[msg.sender].stillAllowed -= creditsBoughtCheap;
                listPrivatePeople[msg.sender].tokenBalance += creditsBoughtCheap;
                circulationToken += creditsBoughtCheap;
                withdrawPrice = this.balance / circulationToken;
        
                return;
            }else{
                // Credits for Cheap + Credits for Expensive 
                input = msg.value;
                input -= listPrivatePeople[msg.sender].stillAllowed * tokenPrice;
                maxCheap = listPrivatePeople[msg.sender].stillAllowed;
                listPrivatePeople[msg.sender].stillAllowed -= maxCheap;
                listPrivatePeople[msg.sender].tokenBalance += maxCheap;
                circulationToken += maxCheap;
            
                creditsBoughtExp = input / expensiveTokenPrice;
                listPrivatePeople[msg.sender].tokenBalance += creditsBoughtExp;
                circulationToken += creditsBoughtExp;
                withdrawPrice = this.balance / circulationToken;
            }
            
        }
    }

  
    
    //Fallback function
    function(){throw;}
    
    // Testing function.
    function defaultCompany() public {
        listCompanies[msg.sender] = Company("foo", 100, 0, 0,0);
    }
    
}