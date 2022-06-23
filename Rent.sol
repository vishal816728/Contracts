//SPDX-License-Identifier:MIT
pragma solidity^0.8.0;

contract tenant{
    address public Manager;
    
    constructor(){
        Manager=msg.sender;
    }

    struct HouseDetails{
        uint houseid;
        address payable owner;
        uint Rent;
        uint SecurityDeposit;
        uint penality;
        uint phoneNumber;
        bool isRented;
    }
    
    event HouseDetailsEvent(
        uint houseid,
        address owner,
        address tenant,
        uint Rent,
        uint SecurityDeposit,
        uint penality,
        uint phoneNumber
    );
    
    modifier OnlyManager() {
        require(msg.sender==Manager,"you are not authorized to list the properties");
        _;
    }

    HouseDetails[] public Housearr; 
    mapping(address=>HouseDetails) OwnerHouseDetail;
    uint counter=0;
    address[] userkycArr;
    mapping(address=>bool) userkycmap;

   function ListtheProperty(address _addr,uint _rent,uint _secdepo,uint _penality,uint _phoneNumber) public OnlyManager{
       require(OwnerHouseDetail[msg.sender].isRented==false,"you have list and rent this property");
       Housearr.push(HouseDetails(counter,payable(_addr),_rent,_secdepo,_penality,_phoneNumber,false));    
       counter++;
   }
    
    function penalityNotification() external pure returns(string memory){
        return "penality will be applicable only if you are failed to delay payments after 7 days. for each weak 2.5% of the total rent.";
    }

    function userkyc(address _addr) public {
        // for(uint i=0;i<userkycArr.length;i++){
        //     if(userkycArr[i]!=_addr){
        //         userkycArr.push(_addr);
        //     }
        // }
        require(userkycmap[_addr]==false,"you have registered with us.");
            userkycmap[msg.sender]=true;
            userkycArr.push(_addr);
        }

    function findtheuser(address _addr) public view returns(bool){
        for(uint i=0;i<userkycArr.length;i++){
            if(userkycArr[i]==_addr){
               return true;
            }else{
                return false;
            }
        }
    }   

    function checkpropertiesAvailable() external view returns(
        uint[] memory,
        address[] memory,
        uint[] memory,
        uint[] memory,
        uint[] memory ,
        uint[] memory,
        bool[] memory
    ){
     
         uint[] memory houseid=new uint[](Housearr.length);
         address[] memory owner=new address[](Housearr.length);
         uint[] memory Rent=new uint[](Housearr.length);
         uint[] memory SecurityDeposit=new uint[](Housearr.length);
         uint[] memory penality=new uint[](Housearr.length);
         uint[] memory phoneNumber=new uint[](Housearr.length);
         bool[] memory isRented=new bool[](Housearr.length);
         
         for(uint i=0;i<Housearr.length;i++){
             houseid[i]=Housearr[i].houseid;
             owner[i]=Housearr[i].owner;
             Rent[i]=Housearr[i].Rent;
             SecurityDeposit[i]=Housearr[i].SecurityDeposit;
             penality[i]=Housearr[i].penality;
             phoneNumber[i]=Housearr[i].phoneNumber;
             isRented[i]=Housearr[i].isRented;
         }
         return (houseid,owner,Rent,SecurityDeposit,penality,phoneNumber,isRented);
    }
    

    
      // mapping to get to know user is tenant or not
      mapping(address=>bool) public istenant;

      // function from which any user can rent the property
      function userRenttheHouse(uint _houseid) external payable returns(bool,uint){
             require(istenant[msg.sender]==false,"you have already rented one house.");
             require(Housearr[_houseid].isRented==false,"house you want has already been rented to someone else.");
             require(userkycmap[msg.sender]==true,"please verfiy yourself first.");
             userHouseDetails[msg.sender]=Housearr[_houseid];
             Housearr[_houseid].isRented=true;
             istenant[msg.sender]=true;  
             require(msg.value>=Housearr[_houseid].Rent,"you should only send the equivalent value");
             //transfer payment to the owner of the house 
            //  payable(Housearr[_houseid].owner).transfer((Housearr[_houseid].Rent+1 ether));
            Housearr[_houseid].owner.transfer(msg.value);
            TenantRentExpiryDate[msg.sender]=block.timestamp+3 minutes;
              return (true,Housearr[_houseid].Rent);
             //event 
                emit HouseDetailsEvent(
        _houseid,
        Housearr[_houseid].owner,
        msg.sender,
        Housearr[_houseid].Rent,
        Housearr[_houseid].SecurityDeposit,
        Housearr[_houseid].penality,
        Housearr[_houseid].phoneNumber
    );            
    }
    //mapping to get to know in which house the tenant is right now

      mapping(address=>HouseDetails) userHouseDetails;

      mapping(address=>uint) public TenantRentExpiryDate;

      mapping(address=>uint) public TenantPenality;
      
      //user rented which house

      function URWH() public view returns(
        uint,
        address,
        uint,
        uint,
        uint,
        uint
      ){
          require(istenant[msg.sender]==true,"you don't rent any house till now.");
          return (
              userHouseDetails[msg.sender].houseid,
              userHouseDetails[msg.sender].owner,
              userHouseDetails[msg.sender].Rent,
              userHouseDetails[msg.sender].SecurityDeposit,
              userHouseDetails[msg.sender].penality,
              userHouseDetails[msg.sender].phoneNumber
              
          );
      }
      

      function TenantPenalityCheck(uint _houseId,address _addr) payable public {
             require(msg.sender==Housearr[_houseId].owner,"only house owner can call it");
             require(istenant[_addr]==true,"you have already rented one house.");
             require(userkycmap[_addr]==true,"please verfiy yourself first.");
             uint fees=msg.value;
             require(fees>=2000,"fees is not correct");
             if(block.timestamp>(TenantRentExpiryDate[_addr]+2 minutes)){
                 TenantPenality[_addr]+=Housearr[_houseId].penality;
             }

             if(block.timestamp>(TenantRentExpiryDate[msg.sender]+4 minutes)){
                 TenantPenality[_addr]+=Housearr[_houseId].penality*2;
             }

             // it is fees from which Manager (owner) wiil earn money
             payable(address(this)).transfer(fees);
      }
      

      function withdrawalofFees() public {
          require(msg.sender==Manager,"only Manager can withdraw the money.");
          require(address(this).balance>0,"no amount exist to transfer");
          payable(Manager).transfer(address(this).balance);
      }

      function getBalance() public view returns(uint){
          require(msg.sender==Manager,"only Manager can withdraw the money.");
          
          return address(this).balance;
      }

}