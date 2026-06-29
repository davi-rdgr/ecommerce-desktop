import 'package:signals_flutter/signals_flutter.dart';

typedef MenuItem = ({
  String name,
  String description,
  double price,
  bool available,
});

typedef Adicional = ({String name, double price});

class MenuController {
  final headerTitle = 'Cardápio';
  final headerSubtitle = 'Edite itens, preços e disponibilidade';

  static const categories = [
    'Baurús',
    'X-Burgers',
    'Cachorro Quente',
    'Pizzas',
    'Porções',
    'Bebidas',
  ];

  static const categoryEmojis = ['🥪', '🍔', '🌭', '🍕', '🍟', '🥤'];

  static const items = <String, List<MenuItem>>{
    'Baurús': [
      (name: 'Baurú Alcatra',  description: 'Alcatra picada, queijo, presunto, alface, tomate, milho, ervilha',  price: 29, available: true),
      (name: 'Baurú Filé',     description: 'Carne de filé picada, queijo, presunto, salada, milho, ervilha',    price: 31, available: true),
      (name: 'Baurú da Casa',  description: 'Alcatra, coração, filé de porco, batata palha, cebola, queijos',    price: 33, available: true),
      (name: 'Baurú Insano',   description: 'Filé de porco, bacon, ovo, provolone, mussarela e cheddar',         price: 30, available: true),
      (name: 'Baurú Família',  description: 'Pão de pizza 25cm, serve até 4 pessoas',                            price: 89, available: true),
    ],
    'X-Burgers': [
      (name: 'X-Tudo',     description: 'Blend 180g, bacon, ovo, queijo, alface e tomate', price: 38, available: true),
      (name: 'X-Bacon',    description: 'Blend 180g, bacon crocante e cheddar',             price: 34, available: true),
      (name: 'X-Lombinho', description: 'Lombo, queijo e molho da casa',                    price: 32, available: true),
      (name: 'X-Egg',      description: 'Blend 150g, ovo e mussarela',                      price: 28, available: true),
      (name: 'X-Salada',   description: 'Blend 150g, alface, tomate e maionese',            price: 26, available: false),
    ],
    'Cachorro Quente': [
      (name: 'Dog Show',    description: 'Salsicha, purê, milho, ervilha e batata palha', price: 18, available: true),
      (name: 'Dog Duplo',   description: 'Duas salsichas com recheio especial',            price: 24, available: true),
      (name: 'Dog Simples', description: 'Salsicha com mostarda e ketchup',                price: 14, available: true),
    ],
    'Pizzas': [
      (name: 'Pizza Calabresa',   description: 'Calabresa fatiada, cebola e azeitona', price: 52, available: true),
      (name: 'Pizza Mussarela',   description: 'Mussarela fresca e manjericão',         price: 48, available: true),
      (name: 'Pizza Frango',      description: 'Frango desfiado, catupiry e milho',     price: 55, available: true),
      (name: 'Pizza Portuguesa',  description: 'Presunto, ovos, cebola e azeitonas',   price: 58, available: false),
    ],
    'Porções': [
      (name: 'Batata Frita',     description: 'Porção crocante com molho especial', price: 22, available: true),
      (name: 'Batata Rústica',   description: 'Com casca e tempero da casa',         price: 26, available: true),
      (name: 'Torre de Batatas', description: 'Batata frita empilhada com cheddar',  price: 34, available: true),
      (name: 'Nuggets',          description: '10 unidades com molho barbecue',      price: 24, available: true),
    ],
    'Bebidas': [
      (name: 'Refri Lata',   description: 'Coca-Cola, Guaraná ou Fanta 350ml', price: 7,  available: true),
      (name: 'Refri 2L',     description: 'Coca-Cola ou Guaraná 2 litros',     price: 14, available: true),
      (name: 'Suco Natural', description: 'Laranja, limão ou maracujá',        price: 12, available: true),
      (name: 'Água Mineral', description: 'Com ou sem gás 500ml',              price: 5,  available: false),
    ],
  };

  static const adicionais = <Adicional>[
    (name: 'Bacon',          price: 5),
    (name: 'Ovo',            price: 3),
    (name: 'Queijo extra',   price: 4),
    (name: 'Cheddar cremoso', price: 4),
    (name: 'Catupiry',       price: 5),
    (name: 'Carne em dobro', price: 9),
  ];

  final selectedCategory = signal(0);

  void selectCategory(int index) => selectedCategory.value = index;

  void dispose() {
    selectedCategory.dispose();
  }
}
