using BKFluentChat.Models;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BKFluentChat.ViewModels.Pages
{
    public partial class TestViewModel:ObservableObject
    {
        [ObservableProperty]
        private ObservableCollection<ContactGroup> _contactGroups;

        // 新增属性：用于存储被选中项的名称，并驱动右侧UI
        [ObservableProperty]
        private string _selectedItemName;

        public TestViewModel()
        {
            LoadMockData();
        }

        // 新增命令：当任何可点击的项被点击时，此命令将被调用
        [RelayCommand]
        private void SelectItem(object item)
        {
            // 判断被点击项的类型，并提取其 Name 属性
            if (item is ContactGroup group)
            {
                SelectedItemName = group.Name;
            }
            else if (item is Contact contact)
            {
                SelectedItemName = contact.Name;
            }
        }

        private void LoadMockData()
        {
            var workGroup = new ContactGroup { Name = "Work Documents" };
            workGroup.Contacts.Add(new Contact { Name = "Feature Schedule" });
            workGroup.Contacts.Add(new Contact { Name = "Overall Project Plan" });

            var personalGroup = new ContactGroup { Name = "Personal Documents" };
            personalGroup.Contacts.Add(new Contact { Name = "Contractor contact info" });

            var remodelGroup = new ContactGroup { Name = "Home Remodel" };
            remodelGroup.Contacts.Add(new Contact { Name = "Paint Color Scheme" });
            remodelGroup.Contacts.Add(new Contact { Name = "Flooring Woodgrain Type" });
            remodelGroup.Contacts.Add(new Contact { Name = "Kitchen Cabinet Style" });

            ContactGroups =
            [
                workGroup,
                personalGroup,
                remodelGroup
            ];
        }
    }
}
