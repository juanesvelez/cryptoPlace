// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Pagos{
    // ----------------------------------------Declaraciones iniciales-----------------------------------------//
    
    //Instancia del contrato token
    ERC20Basic private token;
    
    //Direccion propietario
    address payable public owner;
    
    // Consturctor 
    constructor () public {
        token = new ERC20Basic(10000);
        owner = msg.sender;
    }
    
    // Estructura de datos para almacenar a los clientes 
    struct cliente {
        string nombre;
        string apellidos;
        uint edad;
        uint tokens_comprados;
        string [] creditos;
    }
    
    //Mapping para el registro de tokens de clientes
    mapping (address => cliente) public Clientes;
    
    //Mapping para registro de Clientes
    mapping(string => cliente) public NombreCliente;
    
    // ----------------------------------------Gestion de Tokens--------------------------------------------//
    
    // Funcion para estableces el precio de un token
    function PrecioToken(uint _numTokens) internal pure returns (uint){
        // Conversion de tokens a USDC (stable Coin)
        return _numTokens* (1 ether);
    }
    
    //Funcion para comprar tokens
    function ComprarTokens(uint _numTokens)public payable {
        // establecer el precio de tokens
        uint coste = PrecioToken(_numTokens);
        // Se evalua el dinero del cliente
        require (msg.value >= coste, "No tienes suficiente dinero en tu wallet");
        // Diferencia de lo q el cliente pragma
        uint returnValue = msg.value - coste;
        // La plataforma la cantidad de ethers al cliente
        msg.sender.transfer(returnValue);
        // Obtener numero de tokens disponibles
        uint Balance = balanceOf();
        require(_numTokens <= Balance, "Compra un numero menor de tokens");
        // Transferencia de tokens comprados al cliente
        token.transfer(msg.sender, _numTokens);
        // Registro de tokens comprados
        Clientes[msg.sender].tokens_comprados += _numTokens;
        
    }
    
    function balanceOf() public view returns (uint) {
        return token.balanceOf(address(this));
    }
    
    // Visualizar el numero de tokens restantes de un Cliente
    function MisTokens() public view returns (uint){
        return token.balanceOf(msg.sender);
    }
    
    // Funcion para generar mas tokens
    function GenerarTokens(uint _numTokens) public Unicamente(msg.sender) {
        token.increaseTotalSupply(_numTokens);
    }
    
    // Modificador para controlar las funciones ejecutables por Disney
    modifier Unicamente(address _direccion){
        require(_direccion == owner, "No tienes permisos para ejectuar esta funcion.");
        _;
    }
    
    // ----------------------------------------Gestion Plataforma--------------------------------------------//
    
    //Eventos
    event disponibilidad(string, uint, address);
    event nueva_comodidad(string, uint);
    event no_disponibilidad(string);
    
    // Estructura de alojamientop
    struct alojamiento {
        string nombre_alojamiento;
        uint precio_alojamiento;
        bool estado_alojamiento;
    }
    
    // Mappiny para relacion ar un nombre de inmueble con una estructura de datos del inmueble
    mapping (string => alojamiento) public MappingAlojamiento;
    
    // Array para almacenar las alojaminetos;
    string [] Alojamiento;

    // Mapping para relacion una identidad (Cliente) con su historial 
    mapping (address => string[]) HistorialAlojamiento;
    
    // Crear nuevas comodid solo es ejecutbale por el propietario
    function NuevoAlojamiento(string memory _nombreAlojamiento, uint _precio) public Unicamente(msg.sender) {
        // Creacion de nueva Comodidad
        MappingAlojamiento[_nombreAlojamiento] = alojamiento(_nombreAlojamiento, _precio, true);
        // Almacenamiento del evento para la nueva cpmodidad;
        Alojamiento.push(_nombreAlojamiento);
        // Emision del evento para la Comodidad
        emit nueva_comodidad(_nombreAlojamiento, _precio);
    }
    

    function BajaAlojamiento(string memory _BajaAlojamiento) public Unicamente(msg.sender){
        // El estado de el al pasa a FALSE => No está disponible
        //require(MappingAlojamiento[_BajaAlojamiento].nombre_alojamiento != 0);
        MappingAlojamiento[_BajaAlojamiento].estado_alojamiento = false;
        // Emision de evento para informar que el alojamiento no está disponible
        emit no_disponibilidad(_BajaAlojamiento);
    }
    
        function Subir_Alojamiento(string memory _BajaAlojamiento) public Unicamente(msg.sender){
        // El estado de el al pasa a FALSE => No está disponible
        //require(MappingAlojamiento[_BajaAlojamiento].nombre_alojamiento != 0);
        MappingAlojamiento[_BajaAlojamiento].estado_alojamiento = true;
        // Emision de evento para informar que el alojamiento no está disponible
        emit no_disponibilidad(_BajaAlojamiento);
    }
        function BajaAlojamiento_por_pago(string memory _BajaAlojamiento) private{
        // El estado de el al pasa a FALSE => No está disponible
        //require(MappingAlojamiento[_BajaAlojamiento].nombre_alojamiento != 0);
        MappingAlojamiento[_BajaAlojamiento].estado_alojamiento = false;
        // Emision de evento para informar que el alojamiento no está disponible
        emit no_disponibilidad(_BajaAlojamiento);
    }
    
    // Ver disponibilidad de alojamientos
    function AlojamientosDisponibles() public view returns ( string [] memory){
        return Alojamiento;
    }
    
    // funcion para pagar un Alojamiento
    
    function PagarAlojamiento(string memory _nombreAlojamiento) public {
        // Precio de la atraccion (en tokne)
        uint tokens_alojamiento = MappingAlojamiento[_nombreAlojamiento].precio_alojamiento;
        // Verifica el estado del Alojamiento (si esta disponible)
        require (MappingAlojamiento[_nombreAlojamiento].estado_alojamiento == true,
        "El alojamiento no está disponible para su uso");
        // Verificar el numero de tokens q tiene el cliente 
        require(tokens_alojamiento <= MisTokens(), "No tienes dinero suficiente para esta transaccion");
        /* El clieente paga el alojamiento en tokens:
        - Ha sido necesario crrear otra funcion en ERC20.sol con el nombre transfer_to_owner
        debido a que en caso de usar el transfer o transferFrom las direccion que se escogian 
        para realizar la transaccion eran equivocadas. Ya que el msg.sender que recibia el metodo 
        transferFrom era la direccion del contrato
        */
        token.transfer_to_owner(msg.sender, address(this), tokens_alojamiento);
        // Almacenamiento en el historial del cleinte
        HistorialAlojamiento[msg.sender].push(_nombreAlojamiento);
        // Emision de evento  de alojamiento
        emit disponibilidad(_nombreAlojamiento, tokens_alojamiento, msg.sender);
        BajaAlojamiento_por_pago(_nombreAlojamiento);
        
    }
    
    // Visualizar historial de cliente
    function Historial() public view returns (string [] memory){
        
        return HistorialAlojamiento[msg.sender];
    }
}
