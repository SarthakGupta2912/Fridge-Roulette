import 'package:flutter_test/flutter_test.dart';

import 'package:fridge_roulette/data/ingredients.dart';
import 'package:fridge_roulette/services/label_reader.dart';

Set<String> _ids(String text) {
  return foodsFromLabelText(text).map((Ingredient food) => food.id).toSet();
}

void main() {
  group('food class mapping', () {
    test('reads FoodSeg103 names, including padded and combined names', () {
      expect(findFoodFromFoodSegClass('milk')?.id, 'milk');
      expect(findFoodFromFoodSegClass('cheese butter')?.id, 'cheese');
      expect(findFoodFromFoodSegClass(' hanamaki baozi')?.id, 'dumplings');
      expect(findFoodFromFoodSegClass('French beans')?.id, 'beans');
      expect(findFoodFromFoodSegClass('white button mushroom')?.id, 'mushroom');
      expect(findFoodFromFoodSegClass('background'), isNull);
      expect(findFoodFromFoodSegClass('other ingredients'), isNull);
      expect(findFoodFromFoodSegClass('not a food'), isNull);
    });

    test('keeps the COCO mapping for common foods', () {
      expect(findFoodFromCocoClass('hot dog')?.id, 'hot_dog');
      expect(findFoodFromCocoClass('banana')?.id, 'banana');
      expect(findFoodFromCocoClass('refrigerator'), isNull);
    });

    test('every ingredient has a unique id and can be added by hand', () {
      final List<String> ids = allIngredients
          .map((Ingredient food) => food.id)
          .toList();
      expect(ids.toSet().length, ids.length);
      expect(commonFoodIds.toSet().length, commonFoodIds.length);

      for (final String id in commonFoodIds) {
        expect(findIngredient(id), isNotNull, reason: 'missing food: $id');
      }
      for (final String id in ids) {
        expect(
          commonFoodIds,
          contains(id),
          reason: 'food cannot be added by hand: $id',
        );
      }
    });
  });

  group('package label reading', () {
    test('finds a brand and a cheese name in one label', () {
      expect(_ids('PHILADELPHIA CREAM CHEESE'), <String>{'cheese'});
      expect(_ids('Cheddar Cheese'), <String>{'cheese'});
      expect(_ids('Mozzarella'), <String>{'cheese'});
    });

    test('reads milk, eggs, bread, meat and fish', () {
      expect(_ids('Milk 2%'), <String>{'milk'});
      expect(_ids('Large Eggs'), <String>{'eggs'});
      expect(_ids('Whole Wheat Bread'), <String>{'bread'});
      expect(_ids('Chicken Breast'), <String>{'chicken'});
      expect(_ids('Salmon Fillets'), <String>{'fish'});
      expect(_ids('Breakfast Sausages'), <String>{'sausage'});
    });

    test('does not turn long words into short foods', () {
      expect(_ids('Eggplant'), <String>{'eggplant'});
      expect(_ids('Best before date'), isEmpty);
      expect(_ids('Nutrition facts'), isEmpty);
      expect(_ids('No Name'), isEmpty);
    });

    test('keeps multi-word foods together', () {
      expect(_ids('Peanut Butter'), <String>{'peanut_butter'});
      expect(_ids('Almond Butter'), <String>{'nuts'});
      expect(_ids('Almond Milk'), <String>{'milk'});
      expect(_ids('Ice Cream'), <String>{'ice_cream'});
      expect(_ids('Potato Chips'), <String>{'chips'});
      expect(_ids('Tortilla Chips'), <String>{'chips'});
      expect(_ids('Sweet Potato Fries'), <String>{'fries'});
      expect(_ids('Sour Cream'), <String>{'yogurt'});
      expect(_ids('Hot Dog'), <String>{'hot_dog'});
      expect(_ids('Hamburger'), <String>{'burger'});
    });

    test('reads a short ingredients list and a may-contain warning', () {
      expect(_ids('Ingredients: milk, eggs, cheese'), <String>{
        'milk',
        'eggs',
        'cheese',
      });
      expect(_ids('May contain peanuts'), <String>{'nuts'});
    });

    test('reads common French labels', () {
      expect(_ids('Lait 2%'), <String>{'milk'});
      expect(_ids('Fromage'), <String>{'cheese'});
      expect(_ids('Beurre'), <String>{'butter'});
      expect(_ids('Oeufs'), <String>{'eggs'});
      expect(_ids('Pomme de terre'), <String>{'potato'});
      expect(_ids('Pommes de terre'), <String>{'potato'});
      expect(_ids('Pâtes'), <String>{'pasta'});
      expect(_ids('Croustilles'), <String>{'chips'});
      expect(_ids('Beurre d\'arachide'), <String>{'peanut_butter'});
      expect(_ids('Jus d\'orange'), <String>{'drink', 'orange'});
    });

    test('does not read pantry staples as fridge foods', () {
      expect(_ids('Sea salt'), isEmpty);
      expect(_ids('Black pepper'), isEmpty);
      expect(_ids('Olive oil'), isEmpty);
    });
  });
}
