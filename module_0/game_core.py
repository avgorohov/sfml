def game_core(number):
    '''Сначала вычисляем середину отрезка, а потом отрезаем левую или правую половину в зависимости от того, больше она или меньше нужного.
       Функция принимает загаданное число и возвращает число попыток'''
    count = 1
    start = 1
    end = 101
    predict = (start + end) // 2
    while number != predict:
        count+=1
        if number > predict: 
            start = predict + 1
        elif number < predict: 
            end = predict
        predict = (start + end) // 2
    return(count) # выход из цикла, если угадали