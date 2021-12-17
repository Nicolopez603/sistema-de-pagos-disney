// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.4 < 0.8.11;
pragma experimental ABIEncoderV2;

//Importamos solamente el archivo ERC20 ya que dentro del archivo ERC20 esta el import de SafeMath y no es necesario ponerlo
import "./ERC20.sol";

contract Disney{

    //-------------------------------Declaraciones iniciales---------------------------

    //instancia del contrato Token
    ERC20Basic private token;
    
    //Direccion de disney(owner)
    address payable public owner;


    //Constructor
    constructor () public {
        //Cantidad de tokens
        token = new ERC20Basic(100000);

        //Propietario del contrato
        owner = msg.sender;
    }

    //Estructura de datos para almacenar a los clientes de Disney

    struct cliente{
        uint tokens_comprados;
        string [] atracciones_disfrutadas;
    }

    //Mapping para el registro de clientes
    mapping (address => cliente) public Clientes;

     //------------------------------Gestion de tokens-------------------------------

    //Funcion para establecer el precio de un token
    function precioTokens(uint _numTokens) internal pure returns(uint){
        //Devuelve la conversion de un token a ethers: 1 Token = 1 ether
        return _numTokens* (1 ether);
    }

    //Funcion para comprar tokens en disney y disfrutar de sus atracciones
    function comprarTokens(uint _numTokens) public payable {
        //Establecemos el precio de los tokens
        uint coste = precioTokens(_numTokens);
        
        //Se evalua la cantidad de dinero que el cliente paga por los tokens
        require(msg.value >= coste, "Compra menos tokens o paga con mas ethers"); 

        //Diferencia de lo que el cliente pagó
        uint returnValue = msg.value - coste;

        //Disney retorna la cantidad de ethers al cliente
        msg.sender.transfer(returnValue);

        //Balance de tokens para saber cuantos nos queda disponibles
        uint Balance = balanceOf();
        require(_numTokens <= Balance, "Compra un numero menor de tokens");

        //Se transfiere el numero de tokens al cliente que los adquirio
        token.transfer(msg.sender, _numTokens);

        //Registro de tokens comprados por los usuarios
        Clientes [msg.sender].tokens_comprados += _numTokens;

    }

        //Funcion que nos permite ver el balance de tokens de Disney
        function balanceOf() public view returns(uint){
            return token.balanceOf(address(this));
        }


        //Funcion que nos permite visualizar la cantidad de tokens restantes de un cliente
        function misTokens() public view returns(uint){
            return token.balanceOf(msg.sender);
        }

        //Funcion para generar mas tokens
        function generadorTokens(uint _numTokens) public unicamenteEjecutable(msg.sender){
            token.increaseTotalSupply(_numTokens);
        } 

        //Modifier para controlar las funciones ejecutables por disney
        modifier unicamenteEjecutable(address _direccion){
        require(_direccion == owner, "No tenes permisos para ejecutar esta funcion!");
        _;
        }


    //------------------------------Gestion de Disney-------------------------------

    //Eventos

    event disfruta_atraccion(string, uint, address);
    //Evento para cuando haya nueva atraccion
    event nueva_atraccion(string);
    //Evento para cuando se de de baja una atraccion ya sea por mantenimiento o "x" problema
    event baja_atraccion(string);

    event nueva_comida(string, uint ,bool);

    event baja_comida(string);

    event disfruta_comida(string, uint, address);

    //Estructura de la atraccion
    struct atraccion{
        string nombre_atraccion;
        uint precio_atraccion;
        bool estado_atraccion;
    }

    //Estructura de la comida
    struct comida {
        string nombre_comida;
        uint precio_comida;
        bool estado_comida;
    }


    //Mapping para relacionar un nombre de una atraccion con una estructura de datos de la atraccion

    mapping(string => atraccion) public mappingAtracciones;

    mapping (string => comida) public mappingComida;
    
    //Array para almacenar  el nombre de las atracciones
    string [] Atracciones;

    //Array para almacenar comidas

    string [] Comidas;

    //Mapping para relacionar un cliente con su historial en las atracciones
    mapping(address => string[]) historialAtracciones;

    //Mapping para relacionar un cliente con su historial de comidas
    mapping(address => string[]) historialComida;

    //Funcion que permite crear nuevas atracciones unicamente por Disney
    function nuevaAtraccion(string memory _nombreAtraccion, uint _precio) public unicamenteEjecutable(msg.sender){
        //Creacion de una atraccion en disney
        mappingAtracciones[_nombreAtraccion] = atraccion(_nombreAtraccion, _precio, true);

        //Almacenamos en un array el nombre de una atraccion
        Atracciones.push(_nombreAtraccion);

        //Emitimos un nuevo evento para la atraccion que desplegamos recientemente
        emit nueva_atraccion(_nombreAtraccion, _precio);

    }

    //Crear nuevos menus para la comida en disney (Solo sera ejecutable por disney)
    function nuevaComida(string memory _nombreComida, uint _precio) public unicamenteEjecutable(msg.sender){
        //Creacion de una comida
        mappingComida(_nombreComida) = comida(_nombreComida, _precio, true);

        //Almacenamos en un array las comidas de una persona
        Comidas.push(_nombreComida);

        //Emitimos un evento para las nuevas comidas
        emit nueva_comida(_nombreComida, _precio, true);
    }

    //Funcion que nos permite dar de baja a una atraccion
    function bajaAtraccion(string memory _nombreAtraccion) public unicamenteEjecutable(msg.sender){
        //Estado de la atraccion pasa a false = no esta en uso
        mappingAtracciones[_nombreAtraccion].estado_atraccion = false;

        //Emitimos el evento que se dio de baja la atraccion
        emit baja_atraccion(_nombreAtraccion);
    }

    //Dar de baja a una comida
    function bajaComida(string memory _nombreComida) public unicamenteEjecutable(msg.sender){

        mappingComida[_nombreComida].estado_comida = false;

        emit baja_comida(string);    
    }

    //Funcion que nos permite visualizar las atracciones para los usuarios
    function visualizarAtracciones() public view returns(string [] memory) {
        return Atracciones;
    }

    //Visualizar las comidas de disney
    function comidasDisponibles() public view returns(string [] memory){
        return Comidas;
    } 


    //Funcion que nos permite subirnos a una atraccion de disney y pagar con tokens
    function pagarAtraccion(string memory _nombreAtraccion) public{
        //Precio de la atraccion
        uint tokens_atraccion = mappingComida[_nombreAtraccion].precio_atraccion;

        //Verificamos si esta disponible el estado de la atraccion para su uso
        require(mappingAtracciones[_nombreAtraccion].estado_atraccion == true,
                    "La atraccion no esta disponible en estos momentos.");

        //Verificamos el numero de tokens que tiene el cliente para subirse a la atraccion
        require(tokens_atraccion <= misTokens(),
                    "Necesitas mas tokens para subirte a esta atraccion, compra mas tokens por favor!");    
        
        //Envio de tokens por parte del cliente a disney para la atraccion
        token.transferencia_disney(msg.sender, address(this), tokens_atraccion);

        //Almacenamiento en el historial de atracciones del cliente
        historialAtracciones[msg.sender].push(_nombreAtraccion);

        //Emision del evento para disfrutar la atraccion 
        emit disfruta_atraccion(_nombreAtraccion, tokens_atraccion, msg.sender);
    }

    //Funcion que nos permite comprar en disney y pagar con tokens
    function pagarComida(string memory _nombreComida) public{
        //Precio de la comida
        uint tokens_comida = mappingComida[_nombreComida].precio_comida;

        //Verificamos si esta disponible el estado de la comida para su uso
        require(mappingComida[_nombreComida].estado_comida == true,
                    "La comida no esta disponible en estos momentos.");

        //Verificamos el numero de tokens que tiene el cliente para subirse a la atraccion
        require(tokens_comida <= misTokens(),
                    "Necesitas mas tokens para subirte a esta atraccion, compra mas tokens por favor!");    
        
        //Envio de tokens por parte del cliente a disney para comer
        token.transferencia_disney(msg.sender, address(this), tokens_comida);

        //Almacenamiento en el historial de comidas del cliente
        historialComida[msg.sender].push(_nombreComida);

        //Emision del evento para disfrutar la comida
        emit disfruta_comida(_nombreComida, tokens_comida, msg.sender);
    }    



    //Visualizamos el historial completo de atracciones usadas por el cliente
    function historial() public view returns (string [] memory) {
        return historialAtracciones[msg.sender];
    }

        //Visualizamos el historial completo de comidas por el cliente
    function historialComidasCliente() public view returns (string [] memory) {
        return historialComida[msg.sender];
    }



    //Funcion para que un cliente pueda devolver Tokens cuando el desee
    function devolverTokens(uint _numTokens) public payable{
        //El numero de tokens a devolver es positivo
        require(_numTokens>0, "Necesitas devolver una cantidad entera positiva de tokens");

        //El usuario debe tener el numero de tokens que desea devolver
        require(_numTokens <= misTokens(), "No tienes los tokens que deseas devolver, revisa nuevamente por favor");

        //El cliente realiza la devolucion de tokens
        token.transferencia_disney(msg.sender, address(this), _numTokens);

        //Devolucion de ethers al cliente
        msg.sender.transfer(precioTokens(_numTokens));

    }







}

