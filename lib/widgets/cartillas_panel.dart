import 'package:flutter/material.dart';
import '../models/bingo_game.dart';
import 'cartilla_widget.dart';

class CartillasPanel extends StatelessWidget {
  final BingoGame bingoGame;
  final VoidCallback onStateChanged;

  const CartillasPanel({
    super.key,
    required this.bingoGame,
    required this.onStateChanged,
  });

  void _generateNewCartillas() {
    bingoGame.generateCartillas(5);
    onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cartillas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _generateNewCartillas,
                icon: const Icon(Icons.add),
                label: const Text('Nuevas Cartillas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: bingoGame.cartillas.length,
              itemBuilder: (context, cartillaIndex) {
                return CartillaWidget(
                  numbers: bingoGame.cartillas[cartillaIndex],
                  cardNumber: "Cartilla ${cartillaIndex + 1}",
                  date: DateTime.now().toString().split(' ')[0],
                  price: "Bs. 10",
                  onTap: () {
                    bool hasBingo = bingoGame.checkBingo(bingoGame.cartillas[cartillaIndex]);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          hasBingo 
                            ? '¡BINGO! La cartilla ${cartillaIndex + 1} tiene bingo'
                            : 'La cartilla ${cartillaIndex + 1} no tiene bingo aún',
                        ),
                        backgroundColor: hasBingo ? Colors.green : Colors.orange,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 