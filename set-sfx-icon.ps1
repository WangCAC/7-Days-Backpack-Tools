param(
    [Parameter(Mandatory = $true)][string]$SfxModule,
    [Parameter(Mandatory = $true)][string]$IconFile
)

$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;

public static class SfxIconEditor
{
    private delegate bool NameCallback(IntPtr module, IntPtr type, IntPtr name, IntPtr parameter);
    private delegate bool LanguageCallback(IntPtr module, IntPtr type, IntPtr name, ushort language, IntPtr parameter);

    [DllImport("kernel32.dll", EntryPoint = "LoadLibraryExW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadLibraryEx(string path, IntPtr file, uint flags);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool FreeLibrary(IntPtr module);
    [DllImport("kernel32.dll", EntryPoint = "EnumResourceNamesW", SetLastError = true)]
    private static extern bool EnumResourceNames(IntPtr module, IntPtr type, NameCallback callback, IntPtr parameter);
    [DllImport("kernel32.dll", EntryPoint = "EnumResourceLanguagesW", SetLastError = true)]
    private static extern bool EnumResourceLanguages(IntPtr module, IntPtr type, IntPtr name, LanguageCallback callback, IntPtr parameter);
    [DllImport("kernel32.dll", EntryPoint = "BeginUpdateResourceW", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr BeginUpdateResource(string path, bool deleteExisting);
    [DllImport("kernel32.dll", EntryPoint = "UpdateResourceW", SetLastError = true)]
    private static extern bool UpdateResource(IntPtr update, IntPtr type, IntPtr name, ushort language, byte[] data, uint length);
    [DllImport("kernel32.dll", EntryPoint = "EndUpdateResourceW", SetLastError = true)]
    private static extern bool EndUpdateResource(IntPtr update, bool discard);

    public static void Apply(string modulePath, string iconPath)
    {
        byte[] icon = File.ReadAllBytes(iconPath);
        if (icon.Length < 22 || BitConverter.ToUInt16(icon, 2) != 1)
            throw new InvalidDataException("Invalid ICO file.");
        int count = BitConverter.ToUInt16(icon, 4);
        if (count < 1 || icon.Length < 6 + count * 16)
            throw new InvalidDataException("Invalid ICO image table.");

        var groups = new List<Tuple<ushort, ushort>>();
        IntPtr module = LoadLibraryEx(modulePath, IntPtr.Zero, 2);
        if (module == IntPtr.Zero)
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        try
        {
            var groupIds = new List<ushort>();
            NameCallback names = (h, t, name, p) =>
            {
                long value = name.ToInt64();
                if (value > 0 && value <= ushort.MaxValue)
                    groupIds.Add((ushort)value);
                return true;
            };
            if (!EnumResourceNames(module, new IntPtr(14), names, IntPtr.Zero))
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            foreach (ushort groupId in groupIds)
            {
                LanguageCallback languages = (h, t, name, language, p) =>
                {
                    groups.Add(Tuple.Create(groupId, language));
                    return true;
                };
                if (!EnumResourceLanguages(module, new IntPtr(14), new IntPtr(groupId), languages, IntPtr.Zero))
                    throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            }
        }
        finally
        {
            FreeLibrary(module);
        }
        if (groups.Count == 0)
            throw new InvalidDataException("The SFX module has no icon resource group.");

        byte[] groupData = new byte[6 + count * 14];
        Array.Copy(icon, 0, groupData, 0, 6);
        var images = new byte[count][];
        for (int i = 0; i < count; i++)
        {
            int entry = 6 + i * 16;
            uint size = BitConverter.ToUInt32(icon, entry + 8);
            uint offset = BitConverter.ToUInt32(icon, entry + 12);
            if (size == 0 || (ulong)offset + size > (ulong)icon.Length)
                throw new InvalidDataException("Invalid ICO image offset.");
            images[i] = new byte[size];
            Array.Copy(icon, offset, images[i], 0, size);
            Array.Copy(icon, entry, groupData, 6 + i * 14, 12);
            Array.Copy(BitConverter.GetBytes((ushort)(30000 + i)), 0, groupData, 6 + i * 14 + 12, 2);
        }

        IntPtr update = BeginUpdateResource(modulePath, false);
        if (update == IntPtr.Zero)
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        bool committed = false;
        try
        {
            foreach (var group in groups)
            {
                for (int i = 0; i < count; i++)
                    Put(update, 3, (ushort)(30000 + i), group.Item2, images[i]);
                Put(update, 14, group.Item1, group.Item2, groupData);
            }
            if (!EndUpdateResource(update, false))
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            committed = true;
        }
        finally
        {
            if (!committed)
                EndUpdateResource(update, true);
        }
    }

    private static void Put(IntPtr update, ushort type, ushort id, ushort language, byte[] data)
    {
        if (!UpdateResource(update, new IntPtr(type), new IntPtr(id), language, data, (uint)data.Length))
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
    }
}
'@

[SfxIconEditor]::Apply(
    (Resolve-Path -LiteralPath $SfxModule).Path,
    (Resolve-Path -LiteralPath $IconFile).Path
)
