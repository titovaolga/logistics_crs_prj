using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace LogisticDB
{
    /// <summary>
    /// Логика взаимодействия для ReportsWindow.xaml
    /// </summary>
    public partial class ReportsWindow : Window
    {
        LogisticData db;

        public ReportsWindow()
        {
            InitializeComponent();
        }

        public static void ShowReportsDialog(LogisticData db)
        {
            var win = new ReportsWindow();
            win.db = db;
            win.ShowDialog();
        }

    }
}
