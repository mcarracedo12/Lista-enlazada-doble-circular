.data
slist: 		.word 0
cclist: 	.word 0
wclist: 	.word 0
schedv: 	.space 32
menu: 		.ascii "Colecciones de objetos categorizados\n"
		.ascii "====================================\n"
		.ascii "1-Nueva categoria\n"
		.ascii "2-Siguiente categoria\n"
		.ascii "3-Categoria anterior\n"
		.ascii "4-Listar categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Anexar objeto a la categoria actual\n"
		.ascii "7-Listar objetos de la categoria\n"
		.ascii "8-Borrar objeto de la categoria\n"
		.ascii "9-Salir\n"
		.asciiz "Ingrese la opcion deseada: "
error: 		.asciiz "Error: "
return: 	.asciiz "\n"

catName: 	.asciiz "\nIngrese el nombre de una categoria: "
selCat: 	.asciiz "\nSe ha seleccionado la categoria: "
idObj: 		.asciiz "\nIngrese el ID del objeto a eliminar: "
objName: 	.asciiz "\nIngrese el nombre de un objeto: "
success: 	.asciiz "\nLa operación se realizo con exito\n\n"
saludo: 	.asciiz "\nQue tenga un buen día!\n Trabajo realizado por Carracedo y Fernandez Asociados\n \t\tAll rights reserved"
asterisco:	.asciiz "\n* "
estasAca:	.asciiz "\nEstas en la categoria: "
espacio: 	.asciiz " - "

					# Errores
Error101:		.asciiz "\nOpcion no valida\n "
#Al cambiar de categoria
Error201:		.asciiz "\nerror 201: no hay categorías para cambiar \n"
Error202:		.asciiz "\nerror 202: hay una sola categoría. \n" 
#Al imprimir
Error301:		.asciiz "\nerror 301: no hay categorías para listar \n"
#Al borrar
Error401:		.asciiz "\nerror 401: no hay categorías para borrar \n"				
#Al agregar Objeto a la categoria seleccionada
Error501:		.asciiz "\nerror 501: no hay categorías para agregar objeto \n"			
#Al listar los objetos de la categoria en curso
Error601:		.asciiz "\nerror 601: no hay objetos para listar en la categoría en curso \n"
Error602:		.asciiz "\nerror 602: no hay categorías creadas para listar objetos\n"			
#Al borrar un objeto de la cat seleccionada usando un ID
Error701:		.asciiz "\nerror 701: no existen categorías para borrar objetos\n"
ErrorNotFound:		.asciiz "\nnotFound \n" # El ID no es encontrado
Error801:		.asciiz "\nerror 801: La categoria no esta vacia \n"	
		

.text

main:

loop:
		jal printMenu
		
		ori $t0, $v0, 0	
						# compara el contenido de $v0 con el numero en el segundo parametro y salta
      		beq $t0, 1, newcategory
     		beq $t0, 2, nextcategory			
		beq $t0, 3, prevcategory
		beq $t0, 4, listcategory
		beq $t0, 5, delcategory
		beq $t0, 6, newobject
		beq $t0, 7, listobject
		beq $t0, 8, delobject
	 	beq $t0, 9, fin
	 	la $a0, Error101
	 	li $v0, 4
	 	syscall
	 	
		j loop	

printMenu:
      la $a0, menu		# Imprimo menu
      li $v0, 4
      syscall
      li $v0, 5              # Codigo Syscall para leer un entero
      syscall                   # Leo el entero 
      jr $ra
      
#FUNCION ESCENCIAL
																				
smalloc:
		lw $t0, slist			# Carga slist a t0 para y ve si esta vacio o no
		beqz $t0, sbrk			# sbrk (allocate heap memory)    9    $a0 = number of bytes to allocate (16)   $v0 contains address of allocated memory
		move $v0, $t0			# muevo el resultado de la syscall a t0
		lw $t0, 12($t0)			# va al .next del nodo
		sw $t0, slist			# guarda el nodo en slist (apila)
		jr $ra
sbrk:
		li $a0, 16 			# node size fixed 4 words
		li $v0, 9
		syscall 			# return node address in v0
		jr $ra
sfree:
		lw $t0, slist
		sw $t0, 12($a0)			
		sw $a0, slist 			# $a0 node address in unused list
		jr $ra		
								
      
#FUNCIONES
newcategory:			####
		
		addiu $sp, $sp, -4	# mueve puntero pila
		sw $ra, 4($sp)		# Guarda en pila la direccion de la funcion anterior
		la $a0, catName 	# input category name
		jal getblock		
		move $a2, $v0 		# $a2 = *char to category name
		la $a0, cclist 		# $a0 = list
		li $a1, 0 		# $a1 = NULL
		jal addnode		# Devuelve en v0 el nodo para guardarlo en wclist
		lw $t0, wclist		# Categoria en curso en t0 (en el primero es 0)
		sw $v0, wclist 		# update working list if was NULL
		bnez $t0, newcategory_end
		
		la $a0, success
		li $v0, 4
		syscall
		
		j loop
		

newcategory_end:
		
		la $a0, success
		li $v0, 4
		syscall
		lw $ra, 4($sp)		# restaura la direccion de la funcion anterior a retorno 
		addiu $sp, $sp, 4	#restaura puntero
		
		j loop
		
		# a0: list address
		# a1: NULL if category, node address if object (cargado en 138)
		# v0: node address added
	
addnode:			#####
		addi $sp, $sp, -8
		sw $ra, 8($sp)
		sw $a0, 4($sp) 		# aca ahora tiene la lista en la pila
		jal smalloc 		# en v0 esta el espacio reservado de smalloc
		sw $a1, 4($v0) 		# set node content contiene null si es cat es Null, node address if object
		sw $a2, 8($v0) 		# contiene el string
		lw $a0, 4($sp)
		lw $t0, ($a0) 		# first node address
		beqz $t0, addnode_empty_list

addnode_to_end:
		lw $t1, ($t0) 			# last node address
		# update prev and next pointers of new node
		sw $t1, 0($v0)			# direccion del anterior en primer word del nodo
		sw $t0, 12($v0)			# direccion del posterior en cuarta word del nodo
		# update prev and first node to new node
		sw $v0, 12($t1)
		sw $v0, 0($t0)
		
		j addnode_exit

addnode_empty_list:
		sw $v0, ($a0)
		sw $v0, 0($v0)
		sw $v0, 12($v0)

addnode_exit:
		lw $ra, 8($sp)
		addi $sp, $sp, 8

		jr $ra
		# a0: node address to delete
		# a1: list address where node is deleted
	
delnode:				####
		addi $sp, $sp, -8	# mueve el puntero
		sw $ra, 8($sp)		# guarda direccion de retorno en pila
		sw $a0, 4($sp)
		lw $a0, 8($a0) # get block address
		jal sfree # free block
		lw $a0, 4($sp) # restore argument a0
		lw $t0, 12($a0) # get address to next node of a0 guarda en t0 la direccion a nodo siguente
node:
		beq $a0, $t0, delnode_point_self #si es el unico
		lw $t1, 0($a0) # get address to prev node 
		sw $t1, 0($t0)
		sw $t0, 12($t1)
		lw $t1, 0($a1) # get address to first node
again:
		bne $a0, $t1, delnode_exit
		sw $t0, ($a1) # list point to next node
		j delnode_exit

delnode_point_self:
		sw $zero, ($a1) # only one node

delnode_exit:
		jal sfree
		lw $ra, 8($sp)
		addi $sp, $sp, 8
		la $a0,success
		li $v0,4
		syscall
		j loop
		#jr $ra
		# a0: msg to ask
		# v0: block address allocated with string

getblock:
		addi $sp, $sp, -4	# Mueve el puntero
		sw $ra, 4($sp) 		# Carga la direccion de la funcion de la que viene (newcategory)
		li $v0, 4		# Codigo para leer en syscall
		syscall				
		jal smalloc		# Reserva memoria por 16 bytes llamando al sbrk (deja la dir del nodo en v0)
		move $a0, $v0		# Mueve la dir del string guardada en v0 a a0  $a0 = address of input buffer
		li $a1, 16		# $a1 = maximum number of characters to read
		li $v0, 8		# Carga el nombre de lo que va en el nodo
		syscall			# Llama al Read String (8)
		move $v0, $a0		# Devuelve el string a v0
		lw $ra, 4($sp)		# Carga en retorno la direccion a newcategory
		addi $sp, $sp, 4	# Restaura el puntero a donde estaba 
		jr $ra			# Vuelve a newcategory
		
																					
##########################################################################################################################

############################################	CATEGORIA ANTERIOR	############################################
prevcategory:
		la $a0, wclist
        	lw $t0, ($a0)	 	# Recupero la cabeza desde wclist y la dejo en t0
        	beq $t0, $0, catIsEmpty	# Si head es 0 salta a imprimir error lista vacia  
        	
        	la $t1, 0($t0)		# Inicializo el registro que recorre la lista: $t1 (puntero)
        	
		lw $t1, 0($t1)      	# puntero = puntero -> anterior;
		sw $t1, wclist		# actualizo wclist con la "anterior"
		
		beq $t1, $t0, unicaCat
		
		la $a0, estasAca
		li $v0, 4            	# Syscall para imprimir String
        	syscall
        	lw $a0, 8($t1)       	# Si no esta vacia cargamos el nombre de la categoria prev 
        	li $v0, 4            	# Syscall para imprimir String
        	syscall
        	
        	j loop

catIsEmpty:
        	la $a0, Error201		# Carga error 201 no hay Categoria
        	li $v0, 4
        	syscall
    
        	j loop
				
unicaCat: 	la $a0, estasAca
		li $v0, 4            		# Syscall para imprimir String
        	syscall
		lw     $a0, 8($t1)       	# Si no esta vacia cargamos el nombre de la categoria actual
        	li     $v0, 4            	# Syscall para imprimir String
        	syscall
        	la     $a0, Error202
        	li     $v0, 4
        	syscall
		j loop	

############################################	CATEGORIA SIGUIENTE	############################################
nextcategory:
		la $a0, wclist
        	lw $t0, ($a0)	 	# Recupero la cabeza desde wclist y la dejo en t0
        	beq $t0, $0, catIsEmpty	# Si head es 0 salta a imprimir error lista vacia  
        	
        	la $t1, 0($t0)		# Inicializo el registro que recorre la lista: $t1 (puntero)
        	
		lw $t1, 12($t1)      	# puntero = puntero -> siguiente;
		sw $t1, wclist		# actualizo wclist con la "siguiente"
		
		beq $t1, $t0, unicaCat
		la $a0, estasAca
		li $v0, 4            	# Syscall para imprimir String
        	syscall
        	lw $a0, 8($t1)       	# Si no esta vacia cargamos el nombre de la categoria siguiente 
        	li $v0, 4            	# Syscall para imprimir String
        	syscall
        	
        	j loop


############################################	PARA IMPRIMIR CATEGORIAS	############################################
listcategory:
		la $a0, wclist		#
        	lw $t0, ($a0)	 	# Recupero la cabeza desde cclist y la dejo en t0
        	beq $t0, $0, ListEmpty	# Si head es 0 salta a imprimir error lista vacia  
        	
        	la $t1, 0($t0)		# Inicializo el registro que recorre la lista: $t1 (puntero)
		la $a0, asterisco
		li $v0, 4            	# Syscall para imprimir String
        	syscall
imprimoCat: 
		lw $a0, 8($t1)       	# Si no esta vacia cargamos el nombre de la categoria actual TAMOS ACA
        	li $v0, 4            	# Syscall para imprimir String
        	syscall
        	
		lw $t1, 12($t1)      	# puntero = puntero -> siguiente;
		beq $t1, $t0, loop	# Hasta llegar a la actual
        	bne $t1, $t0, imprimoCat
        	
	  	jr $ra			# Salir de la funcion

ListEmpty:
        	la $a0, Error301	# Carga error 301 no hay Categoria
        	li $v0, 4
        	syscall
    
        	j loop


################################################	AGREGAR OBJETO A CATEGORIA ACTUAL	################################################

newobject:			####
		la $a0, cclist
        	lw $t0, ($a0)	 	# Recupero la cabeza desde cclist y la dejo en t0
        	beq $t0, $0, noCatsParaAgregar	# Si head es 0 salta a imprimir error lista vacia  
		
		addiu $sp, $sp, -4	# mueve puntero pila
		sw $ra, 4($sp)		# Guarda en pila la direccion de la funcion anterior
		la $a0, objName 	# input object name
		jal getblock		# deja en v0 el string
		move $a2, $v0 		# $a2 = *char to object name
		lw $t6, wclist		# bajo la direccion de la wclist (Categoria)
		
		la $a0, 4($t6)		# $a0 = list Direccion del nodo en la categoria
		
		jal addnode		#  Le da contenido al nodo Devuelve en v0 el nodo para guardarlo
		
		la $a1, ($v0)		# $a1 = objectNode address
		
	 	sw $a1, 4($t6)		# Actualizo cabeza
		bnez $t0, newcategory_end
		
		la $a0, success
		li $v0, 4
		syscall
		
		j loop

		# a0: list address
		# a1: NULL if category, node address if object (cargado en 138)
		# v0: node address added
		

noCatsParaAgregar: 
        	la $a0, Error501	# Carga error no hay Categoria para agregar objeto
        	li $v0, 4
        	syscall
    
        	j loop

############################################	PARA IMPRIMIR OBJETOS	############################################
listobject:
		la $a0, cclist
        	lw $t0, ($a0)	 	# Recupero la cabeza desde cclist y la dejo en t0
        	beq $t0, $0, noCatsParaListar	# Si head es 0 salta a imprimir error lista vacia  
		
		lw $a0, wclist
        	lw $t0, 4($a0)	 	# Recupero la cabeza desde wclist y la dejo en t0
        	beq $t0, $0, CatEmpty	# Si head es 0 salta a imprimir error lista vacia  
        	
        	move $t1, $t0		# Inicializo el registro que recorre la lista: $t1 (puntero)
		li $t5, 0
imprimoObject: 
		addi $t5, $t5, 1	#Agrego 1 a t0 para enumerar
		
		move $a0, $t5
		li $v0, 1            	# Syscall para imprimir numero
        	syscall
        	
        	la $a0, espacio
        	li $v0, 4
        	syscall
        	
		lw $a0, 8($t1)       	# Cargamos el nombre de la categoria actual 
        	li $v0, 4            	# Syscall para imprimir String
        	syscall
        	
		lw $t1, 12($t1)      	# puntero = puntero -> anterior;
		
		beq $t1, $t0, loop	# Hasta llegar a la actual
		   	
        	bne $t1, $t0, imprimoObject
        	
        	j loop
	  	
CatEmpty:
        	la $a0, Error601	# Carga error 601 no hay Categoria
        	li $v0, 4
        	syscall
    
        	j loop

noCatsParaListar: 
        	la $a0, Error602	# Carga error no hay Categoria para listar objetos
        	li $v0, 4
        	syscall
    
        	j loop

################################################      BORRAR OBJETO     ############################################################ 

delobject:	la $a0, cclist
        	lw $t0, ($a0)	 	# Recupero la cabeza desde cclist y la dejo en t0
        	beq $t0, $0, noCats	# Si head es 0 salta a imprimir error lista vacia  
     	
		lw $t7, wclist		# a1: list address where node is deleted
        	lw $a1, 4($t7)	 	# Recupero wclist y la dejo en a1 la direccion de lista de objetos para pasar como argumento
        	beq $a1, $0, CatEmptyNotDelete	# Si head es 0 salta a imprimir error lista vacia  
        	
        	la $a0,idObj		# pido por teclado el Id del objeto a borrar
        	li $v0,4
        	syscall
        	li $v0,5
        	syscall
        	move $t3,$v0		# Cargo en t3 el ID ingresado por teclado
        		
        	move $a0, $a1					
		li $t5, 1
		
		# a0: node address to delete			
		# a1: list address where node is deleted	category list	
						
		beq $t5, $t3, actualizoHead     #comparo id ingresado con el contador 
		
 		# Si no es la cabeza:
		lw $a0, 12($a0)		# Inicializo el registro que recorre la lista: $a0 (puntero) direccion de siguiente
		addi $t5, $t5, 1               #Agrego 1 a t5 para contar  
		 
findObject:	beq $t5, $t3, delnode           #comparo id ingresado con el contador 
		lw $a0, 12($a0)
		addi $t5, $t5, 1               #Agrego 1 a t5 para contar 
		beq $a0, $a1, objNotFound	# Hasta llegar a la actual
		j findObject
		
actualizoHead: 	
		# Si es la cabeza:
		lw $t2, 12($a0)	
			
		sw $t2, 4($t7) 			# actualizo head con siguiente 
		bne $t2, $a0, delnode		# Si la direccion que voy a borrar es la cabeza, y es igual a posterior
						#Es el unico, pongo direccion en 0
		li $t0, 0
		sw $t0, 4($t7)			# pongo 0 como direccion a lista de objetos para que se sepa que esta vacia

		j delnode
		
objNotFound:
		la $a0, ErrorNotFound 	#ErrorNotFound:.asciiz "\nnotFound \n" # El ID no es encontrado
		li $v0, 4
		syscall
		j loop
	  
noCats: 	la $a0, Error701		# pido por teclado el Id del objeto a borrar
        	li $v0,4
        	syscall
        	j loop

CatEmptyNotDelete:
        	la $a0, Error701	# Carga error 601 no hay Categoria
        	li $v0, 4
        	syscall
        	j loop

##################################################	BORRAR CATEGORIA	#############################################################
delcategory:	
		la $a1, cclist
        	lw $t0, ($a1)	 	# Recupero la cabeza desde cclist y la dejo en t0
        	beq $t0, $0, noBorraCats	# Si head es 0 salta a imprimir error lista vacia  
		
		lw $a0, wclist		# a1: list address where node is deleted
        	lw $t0, 4($a0)	 	# Recupero la direccion de wclist y la dejo en t0 (direccion de lista de objetos)
        	bne $t0, $0, CatNotEmpty	# Si head es 0 salta a imprimir error lista vacia  
        	
        	lw $t7, ($a0)
        	sw $t7, wclist		#cambio la wclist a la anterior
		bne $a0, $t7, delnode	#Comparo direccion de categoria actual con anterior
		sw $0, wclist
		
		# a0: node address to delete			
		# a1: list address where node is deleted	category list			
		
		j delnode           	#comparo id ingresado con el contador 
	  
noBorraCats: 	la $a0,Error401		#.asciiz "\nerror 401: no hay categorías para borrar \n"				
        	li $v0,4
        	syscall
        	j loop

CatNotEmpty: 	la $a0, Error801		#.asciiz "\nerror 801: La categoria no esta vacia \n"				
        	li $v0, 4
        	syscall
        	j loop

#################################################	PARA SALIR	####################################################################																																																																																																																																																																																																																								

fin:		la $a0, saludo		# Imprimo saludo
		li $v0, 4
		syscall
		li $v0,10
		syscall
		
























		
