/// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;





contract LandRegistry {

// ************************************************ SOME USEFULE GLOBAL DATA VARIABLES **************************************

    ///@dev used to assign id to the newly registered properties
    uint256 current_property_id = 1;
    ///@dev used to assign id to the newly registered citizen nodes.
    uint256 current_citizen_id = 1000001;
    ///@dev used to assign id to the newly registered validator nodes.
    uint256 current_validator_id = 1;
    ///@dev used to assign a id to a owner,property parir
    uint256 current_ownership_id = 1;
    ///@dev used to assign id to the transaction_id
    uint256 current_transaction_id = 1;
    ///@dev currently set transaction fee
    ///@dev fee can be increased to decrease traffic
    ///@dev important for bogus request to bog up the system
    uint256 current_transaction_fee = 25;

    ///@notice stores the address of the owner of the contract (Here the Goverment)
    ///@dev only he or she can call the certain function
    address contract_owner = address(0);

    ///stores the minmimum votes one need to confirm a transaction
    uint256 threshold = 2;


// ************************************************** REQUIRED STRUCTS **********************************************

    ///@notice structure to store ownership details of a property
    ///@param property_id is the id of the property
    ///@param buying_cost notes the price of the property that the owner bought it for
    ///@param owner_name name of the owner
    ///@param owner_id id of the owner
    ///@param status stores the status of the ownership /OWNING,SOLD
    ///@param proof store a string as proof of ownership /proxy for uploading papers
    struct ownership{
        uint256 ownership_id;
        uint256 property_id;
        uint256 buying_cost;
        uint256 from ;
        uint256 to;
        string owner_name;
        uint256 owner_id;
        string status;
        string proof ;


    }

    ///@notice structure to store ownership details of a property
    ///@param property_address stores the actual address of the property
    ///@param property_id is the id of the property
    ///@param current_owner_id stores the id of the current owner
    ///@param current_proof stores the proof of the current owners ownership
    ///@param current_ownership_id is used to index all past/present ownership
    ///@param status stores the property status / UNVERIFIED(0),VERIFIED
    struct property{
        uint256 property_id;
        string property_address;
        
        uint256 status;
        uint256 current_owner_id;
        string current_proof;
        uint256 current_ownership_id;
        mapping(uint256 => ownership) owners;
    }

    ///@notice structure of the citizen node in the network
    ///@param citizen_id id of the citizen
    ///@param citizen_digital_address stores the digital address of the citizen
    ///@param properties stores a list of all currently and previously owned properties of owner
    ///@param identity_proof is the proof of the citizens id.Something likely uploading an actual addhar card photo 
    ///@param status stores the status/role of the citizen // UNVERIFIED(0),VERIFIED(1)
    ///@param name stores the name of the citizen
    struct citizen{
        uint256 citizen_id;
        address citizen_digital_address;
        string name;
    
        
        string identity_proof;
        uint256 status;
        //mapping(uint256 => property) properties;

    }

    ///@notice struct for the validators
    ///@param validator_id is the id of the validator
    ///@param validator_address address of the validator
    ///@param validations stores the list of validations the validators has endorsed,int is the id of the transactions
    ///@param name of the validator
    ///@param proof some proxy for goverment ID

    ///@param status of the validator // UNVERIFIED(0)/VERIFIED(1)
    struct validator{
        
        uint256 validator_id;
        address validator_address;
        string name ;
        
        uint256 status;
        string proof;
        mapping(uint256 => bool) validations;
        

    }


    ///@notice structure to store ownership details of a property
    ///@param transaction_type "REGISTRATION(0) / TRANSFER(1)"
    ///@param transaction_id stores the id of the transaction
    ///@param property_id is the id of the property
    ///@param seller_id id of the current owner
    ///@param buyer_id id of the new_buyer
    ///@param transaction_id id of the transaction
    ///@param transaction_price selling price /buying price
    ///@param transaction_fee store the fee paid for the transaction,processing fee
    ///@param proof stores the document required to prove the transaction (proxy)
    ///@param votes stores the number of endorsement the transaction has recieved
    ///@param endorsable makes the transaction ready to be endorsable
    ///@param validators the list of endorsers    
    ///@param confirmed becomes true when the transaction is confirmed
    struct transaction{
        uint256 transaction_type ;
        uint256 property_id;
        uint256 seller_id;
        uint256 buyer_id;
        uint256 transaction_id;
        uint256 transaction_price ;
        uint256 transaction_fee;
        string proof;
        //uint256 status ;
        uint256 votes ;
        bool endorsable ;
        bool confirmed ;
        mapping(uint256 => bool) validators;

    }
    

// ****************************************************** EVENTS **************************************************    
    
    ///@dev this event is for when a citizen asks to be registered
    event CitizenValidationRequested(uint256 citizen_id);
    
    ///@dev this event is for when a citizen asks to be registered
    ///@dev one validator can validate a citizen
    event CitizenValidated(uint256 citizen_id,uint256 validator_id);

    ///@dev this event is for when a validator/goverment official ask to be validated
    event ValidatorValidationRequest(uint256 validator_id);

    ///@dev this event is for when owner of the contract validates the validator
    event ValidatorApproved(uint256 validator_id, uint256 role);

    ///@dev this event is for Seller to make Transaction Request
    event SellPropertyRequest(uint256 transaction_id,uint256 seller_id);

    ///@dev this event if for the Buyer to confirm a transaction
    ///@dev seller must make the request first
    event BuyPropertyRequest(uint256 transaction_id,uint256 buyer_id);

    ///@dev this event is for Register Property Request
    event RegisterPropertyRequest(uint256 transaction_id,uint256 owner_id);

    ///@dev this event is for validator to endorse a transaction
    event TransactionEndorsed(uint256 transaction_id,uint256 validator_id);

    ///@dev this event is for when transaction is confirmed 
    event TransactionConfirmed(uint256 transaction_id);

    ///@dev this event is for when property ownership has been modified
    event OwnershipChanged(uint256 property_id,uint256 previous_owner_id,uint256 new_owner_id); 




// ************************************************** GLOBAL DATA STORAGE ************************************


    
    /// @dev  create a list of properties
    mapping(uint256 => property) properties;
    /// @dev create a list of citizens
    mapping(uint256 => citizen) citizens;
    /// @dev create a list of validators 
    mapping(uint256 => validator) validators;
    ///@dev create a list of transactions
    mapping(uint256 => transaction) transactions;
    ///@dev mapping of address to id
    mapping(address => uint256) ids;
    ///@dev mapping of ids to roles /0 for unregistered(default),(1 for unconfirmed citizen),(2 for confirmed citizen)
    ///@dev (3 for unconfirmed validator) ,(4 for confirmed validator)
    mapping(uint256 => uint256) roles;


// ************************************************ MODIFIERS *********************************************

    /// Check whether a given condition is true
    /// @param _condition condition statement to verify.
    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    
    ///@dev only owner of the contract can perform certain actions
    modifier OnlyOwner(){
        require(msg.sender == contract_owner, "You are not allowed to peform this action");
        _;
    }

    ///@notice transaction_id has to be valid
    ///@param transaction_id is the id of the transaction
    modifier ValidTransaction(uint256 transaction_id){
        require(transaction_id < current_transaction_id,"Not a valid Transaction ID");
        _;
    }

            
    ///@notice the buyer has be the same as given in transaction
    /// @param transaction_id id of the transaction
    modifier OnlyBuyer(uint256 transaction_id) {
        require(ids[msg.sender] == transactions[transaction_id].buyer_id,"Transaction id and buyer id doesn't match");
        _;
    }

    ///@notice the buyer has to be confirmed citizen
    /// @param buyer_id  Id of the buyer id.
    modifier ValidBuyer(uint256 buyer_id){
        require(roles[buyer_id] == 2,"Buyer_ID is not appropriate Buyer ID");
        _;
    }

    ///@notice check whether the transaction can be endorsed
    ///@param transaction_id is the id of the transaction
    modifier EndorsableTransaction(uint256 transaction_id){
        require(transactions[transaction_id].endorsable == true,"Cant Endorse this Transaction");
        _; 
                    
    }

      ///@notice check whether the transaction cannot be endorsed
    ///@param transaction_id is the id of the transaction
    modifier UnendorsableTransaction(uint256 transaction_id){
        require(transactions[transaction_id].endorsable != true,"Buyer has already confirmed  this Transaction");
        _; 
                    
    }
    
    

    ///@notice has to be valid citizen 
    modifier ValidCitizen() {
        require(roles[ids[msg.sender]] == 2,"Function Caller Not a Confirmed Citizen");
        _;
    }

    ///@notice has to be valid validator
    modifier ValidValidator() {
        require(roles[ids[msg.sender]] == 4,"Function Caller Not a Confirmed Validator");
        _;
    }
    ///@notice has to be valid validator_id
    ///@param validator_id is the id provided
    modifier ValidValidatorID(uint256 validator_id) {
        require(validator_id < current_validator_id,"The Validator ID is wrong");
        _;
    }

    ///@notice has to be valid citize_id
    ///@param citizen_id is the id of the citizen
    modifier ValidCitizenID(uint256 citizen_id) {
        require(citizen_id < current_citizen_id,"The Validator ID is wrong");
        _;
    }

     ///@notice has to be uncorfimed citizen 
     ///@param citizen_id has to be id of the citizen
    modifier RequestedCitizen(uint256 citizen_id) {
        require(roles[citizen_id] == 1,"Hasn't been asked to be authenticated as Citizen");
        _;
    }

    ///@notice has to be uncomfirmed validator
    ///@param validator_id has to be id of the validator
    modifier RequestedValidator(uint256 validator_id) {
        require(roles[validator_id] == 3,"Hasn't been asked to be authenticated as Validator");
        _;
    }


    
    ///@notice has to be valid property
    ///@param property_id is the id of the property
    modifier ValidPropertyID(uint256 property_id){
        require(property_id < current_property_id,"Invalid Property ID");
        _;

    }

    ///@notice has to be confirmed property
    ///@param property_id is the id of the property
    modifier ConfirmedProperty(uint256 property_id){
        require(properties[property_id].status == 1,"Land Record has to been confirmed to the System");
        _;
    }

    ///@notice Seller has to be owner of the property he is selling
    ///@param property_id is the id of the property
    modifier ValidSeller(uint256 property_id){
        require(properties[property_id].current_owner_id == ids[msg.sender],"Only Owner of the property can sell the property");
        _;
    }

    ///@notice Used to make sure only unregistered person can register
    modifier Unregistered(){
        require(roles[ids[msg.sender]] == 0,"Already Registered");
        _;
    }

    ///@notice used to ensure transaction fee is paid
    modifier FeePaid(){
        require(msg.value >= current_transaction_fee,"Cannot Request a Transaction Without paying a Fee ");
        _;
    }

    ///@notice transaction should be uncomfirmed
    modifier UnconfirmedTransaction(uint256 transaction_id){
        require(transactions[transaction_id].confirmed == false,"Transaction has already been confirmed");
        _;
    }

    // ************************************************ FUNCTIONS *******************************************



    ///@notice this is like the constructor of the contructor,Owner of the contract calls 
    ///@notice immediately after it is deployed and it stores the owners address
    function start() external {
        contract_owner = msg.sender;

    }

    /// @dev the function is used by the validator to ask to authenticated
    /// @param name of the validator
    /// @param proof some form of goverment issue id 
    function registerValidator(
        string calldata name, 
        string calldata proof) 
        external
        Unregistered() {
        validators[current_validator_id] = validator(
            current_validator_id,
            msg.sender,
            name,
            0,
            proof

        );
        emit ValidatorValidationRequest(current_validator_id);
        roles[current_validator_id] = 3;
        ids[msg.sender] = current_validator_id;
        current_validator_id += 1;

        

    } 

    /// @dev the function is used by the validator to ask to authenticated
    /// @param name of the validator
    /// @param identity_proof some form of goverment issue id 
    function registerCitizen(
        string calldata name, 
        string calldata identity_proof) 
        external
        Unregistered() {

        citizens[current_citizen_id] = citizen(
            current_citizen_id,
            msg.sender,
            name,
            identity_proof,
            0
      
        );
        emit CitizenValidationRequested(current_citizen_id);
        
        ids[msg.sender] = current_citizen_id;
        roles[ids[msg.sender]]= 1;
        current_citizen_id += 1;

        

    }

    ///@dev function is called by owner to approved a unconfirmed validator
    ///@param validator_id is the id of the validator
    function approveValidator(uint256 validator_id)
        external
        OnlyOwner()
        ValidValidatorID(validator_id)
        RequestedValidator(validator_id){
            validators[validator_id].status = 1;
            roles[validator_id] = 4;
            emit ValidatorApproved(validator_id,roles[validator_id]);


    }
    
    ///@dev function is called by approved validator to approv a unconfirmed citizen
    ///@param citizen_id is the id of the citizen
    function endorseCitizen(uint256 citizen_id)
        external
        ValidValidator()
        ValidCitizenID(citizen_id)
        RequestedCitizen(citizen_id){
            citizens[citizen_id].status = 1;
            roles[citizen_id] = 2;
            emit CitizenValidated(citizen_id, ids[msg.sender]);


    }


    ///@dev function to request a property be registered
    ///@param property_address stores the address of the property
    ///@param proof is a proxy for some document to prove ownerhsip
    function registerProperty(string calldata property_address,string calldata proof)
        external
        payable
        ValidCitizen()
        FeePaid(){
            properties[current_property_id] = property(
                current_property_id,
                property_address,
                0,
                0,
                proof,
                1


            );
            transactions[current_transaction_id] = transaction(
                0 ,
                current_property_id,
                0,
                ids[msg.sender],
                current_transaction_id,
                0,
                msg.value,
                proof,
            
                0,
                true,
                false

            );
            emit RegisterPropertyRequest(current_transaction_id,ids[msg.sender]);

            current_property_id += 1;
            current_transaction_id += 1;
            


        }
    

    ///@dev request a transaction by seller to sell a property
    ///@param property_id is the id of the property
    ///@param proof is some sort of proxy for proof
    ///@param transaction_price is the price of the transaction
    function SellProperty(uint256 property_id,uint256 buyer_id,string calldata proof,uint256 transaction_price)
        external
        payable
        ConfirmedProperty(property_id)
        ValidSeller(property_id)
        ValidBuyer(buyer_id)
        FeePaid(){
              transactions[current_transaction_id] = transaction(
                1 ,
                property_id,
                ids[msg.sender],
                buyer_id,
                current_transaction_id,
                transaction_price,
                msg.value,
                proof,

                0,
                false,
                false

            );
            emit SellPropertyRequest(current_transaction_id,ids[msg.sender]);
            current_transaction_id += 1;
    }

    ///@dev buyer confirms the transaction
    ///@param transaction_id is the id of the transaction
    function ConfirmBuy(uint256 transaction_id)
    external
    ValidTransaction(transaction_id)
    UnconfirmedTransaction(transaction_id) 
    UnendorsableTransaction(transaction_id)
    ValidCitizen()
    OnlyBuyer(transaction_id){
        transactions[transaction_id].endorsable = true;
        emit BuyPropertyRequest(transaction_id,ids[msg.sender]);
        
    }

    /// @dev called by the validator to endorse
    /// @dev if neccessary amount of votes has reached confirm transaction
    /// @param transaction_id is the id of the transaction 
    function endorseTransaction(uint256 transaction_id)
    external
    ValidValidator()
    UnconfirmedTransaction(transaction_id)
    ValidTransaction(transaction_id)
    EndorsableTransaction(transaction_id){
        transactions[transaction_id].votes += 1;
        transactions[transaction_id].validators[ids[msg.sender]] = true;
        validators[ids[msg.sender]].validations[transaction_id] = true; 
        if(transactions[transaction_id].votes >= threshold)
        {
            // if the transaction is a registration
            if(transactions[transaction_id].transaction_type == 0){
                uint256 property_id = transactions[transaction_id].property_id;
                properties[property_id].current_owner_id = transactions[transaction_id].buyer_id;
                properties[property_id].status = 1;
                uint256 ownership_id = properties[property_id].current_ownership_id;
                properties[property_id].current_ownership_id += 1;
                properties[property_id].owners[ownership_id] = ownership(
                    ownership_id,
                    property_id,
                    0 , //buying cost is zero as this is registrationa
                    0 , // from is 0 as no previous owner 
                    transactions[transaction_id].buyer_id, //to
                    citizens[transactions[transaction_id].buyer_id].name, // name of the owner
                    transactions[transaction_id].buyer_id, //to
                    "OWNING", // status 
                    transactions[transaction_id].proof

                );
            }
            if(transactions[transaction_id].transaction_type == 1){
                uint256 property_id = transactions[transaction_id].property_id;
                properties[property_id].current_owner_id = transactions[transaction_id].buyer_id;
                properties[property_id].status = 1;
                uint256 ownership_id = properties[property_id].current_ownership_id;
                properties[property_id].owners[ownership_id - 1].status = "SOLD";
                properties[property_id].current_ownership_id += 1;
                properties[property_id].owners[ownership_id] = ownership(
                    ownership_id,
                    property_id,
                    transactions[transaction_id].transaction_price , //buying cost is zero as this is registrationa
                    transactions[transaction_id].seller_id , // 
                    transactions[transaction_id].buyer_id, //to
                    citizens[transactions[transaction_id].buyer_id].name, // name of the owner
                    transactions[transaction_id].buyer_id, //to
                    "OWNING", // status 
                    transactions[transaction_id].proof
                );
                emit OwnershipChanged(property_id,transactions[transaction_id].seller_id,transactions[transaction_id].buyer_id); 

            }
            emit TransactionConfirmed(transaction_id);
        }
        emit TransactionEndorsed(transaction_id,ids[msg.sender]);
 


    }
    /*
    ///@dev function to display all pending Transactions 
    ///@return a list of all pending transactions
    function showAllPendingTransactions() external view returns (transaction[] memory) {
        uint256 indx = 0;
        uint256 pending_size = 0;
        for(uint256 i = 1; i < current_transaction_id; i++) {
            if(transactions[i].confirmed == false){
                 pending_size += 1;

            }
        }
        transaction[] memory pending_transactions = new transaction[](pending_size);
        for(uint256 j = 1; j < current_transaction_id; j++) {
             if(transactions[j].confirmed == false){
                transaction storage currenttransaction = transactions[j];
                pending_transactions[indx] = currenttransaction;
                indx += 1;

             }
        }
        return pending_transactions;
    }
    */


    

    ///@dev function to display all ownership history of a property
    ///@return a list of all previous/current ownership
    ///@param property_id is the id of the property of interest
    function showPastOwnership(uint256 property_id) external view returns (ownership[] memory) {
        uint256 indx = 0;
        uint256 size = properties[property_id].current_ownership_id - 1;
        ownership[] memory past_ownership = new ownership[](size);
        for(uint256 j = 1; j < size + 1; j++) {
            ownership storage ownership_info = properties[property_id].owners[j];
                past_ownership[indx] = ownership_info;
                indx += 1;

        }
        return past_ownership;


    }
}

    

    

    
