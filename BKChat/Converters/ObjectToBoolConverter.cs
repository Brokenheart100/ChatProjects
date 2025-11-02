using Avalonia.Data.Converters;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BKChat.Converters
{
    public class ObjectToBoolConverter : IValueConverter
    {
        // 这个方法负责将源数据（任何对象）转换成目标类型（布尔值）
        public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        {
            // 如果值不是 null，返回 true，否则返回 false
            return value is not null;
        }

        // ConvertBack 通常用于双向绑定，这里我们不需要，所以直接抛出异常
        public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
}
