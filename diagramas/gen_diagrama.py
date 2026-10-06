import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, Ellipse, FancyArrowPatch

fig, ax = plt.subplots(figsize=(19.4, 11), dpi=150)
ax.set_xlim(0, 194); ax.set_ylim(0, 110); ax.axis("off")
fig.patch.set_facecolor("white")

INK = "#1f2937"; MUTED = "#6b7280"
C_USR = "#2563eb"; C_ADM = "#7c3aed"; C_FGT = "#dc2626"; C_SW = "#0f766e"
C_WEB = "#d97706"; C_MG = "#9ca3af"; C_OK = "#16a34a"; C_DB = "#0369a1"


def box(x, y, w, h, title, lines, color, fs=9.0, tfs=12, face="white"):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.5,rounding_size=1.8",
                                linewidth=2, edgecolor=color, facecolor=face, zorder=3))
    ax.text(x + w/2, y + h - 3.0, title, ha="center", va="center", fontsize=tfs, fontweight="bold", color=color, zorder=4)
    for i, t in enumerate(lines):
        ax.text(x + w/2, y + h - 6.8 - i*3.1, t, ha="center", va="center", fontsize=fs,
                color=INK, family="DejaVu Sans Mono", zorder=4)


def link(p1, p2, label=None, color=INK, lw=2.2, ls="-", off=(0, 1.8), fs=8.5):
    ax.plot([p1[0], p2[0]], [p1[1], p2[1]], color=color, lw=lw, ls=ls, zorder=2, solid_capstyle="round")
    if label:
        ax.text((p1[0]+p2[0])/2 + off[0], (p1[1]+p2[1])/2 + off[1], label, ha="center", va="center",
                fontsize=fs, color=MUTED, zorder=5, bbox=dict(boxstyle="round,pad=0.15", fc="white", ec="none"))


ax.text(97, 107, "P3 · Infraestructura 1 — Servidores en DMZ con FortiGate",
        ha="center", fontsize=17, fontweight="bold", color=INK)
ax.text(97, 103.3, "Jose Gabriel Feliz Maria · Matrícula 2025-0742 · Seguridad de Redes (ITLA)",
        ha="center", fontsize=10.5, color=MUTED)

# Internet
ax.add_patch(Ellipse((66, 92), 46, 11.5, facecolor="#f3f4f6", edgecolor=C_MG, lw=2, zorder=1))
ax.text(66, 93.6, "INTERNET (Cloud0)", ha="center", fontsize=11.5, fontweight="bold", color="#4b5563")
ax.text(66, 90.2, "192.168.182.0/24 · gestión + NAT", ha="center", fontsize=8.8, color=INK, family="DejaVu Sans Mono")

# FortiGate
box(48, 56, 36, 24, "Fortinet-DMZ (FortiGate)", ["port1 WAN  192.168.182.60/24", "port2 LAN  10.7.43.17/30",
                                                 "port3 DMZ  10.7.43.1/28", "3 políticas · 2 rutas · DNS"], C_FGT, tfs=11.5)
# Switch
box(4, 56, 34, 24, "SW-A (Cisco, capa 3)", ["Switch de los usuarios", "Vlan10  10.7.42.1/25", "Vlan20  10.7.42.129/25",
                                           "Vlan99  10.7.43.18/30", "DHCP · port-security"], C_SW, tfs=11.5)
# Switch de la DMZ
box(96, 56, 34, 24, "SW-B (Cisco, capa 2)", ["Switch de los servidores", "VLAN 30 SERVIDORES-DMZ", "Vlan30  10.7.43.11/28",
                                              "port-security · BPDU Guard", "puertos sin uso apagados"], C_SW, tfs=11.5)
# Users
box(2, 22, 27, 21, "Usuario VLAN 10", ["VM Windows 10", "DHCP 10.7.42.10", "Cloud2 · e0/1"], C_USR, fs=8.8, tfs=11)
box(33, 22, 27, 21, "Usuario VLAN 20", ["PC administrador", "DHCP 10.7.42.138", "Cloud4 · e0/2"], C_ADM, fs=8.8, tfs=11)

# DMZ zone
ax.add_patch(FancyBboxPatch((140, 16), 50, 70, boxstyle="round,pad=0.5,rounding_size=2.5",
                            linewidth=2.2, edgecolor=C_WEB, facecolor="#fffbeb", ls="--", zorder=1))
ax.text(165, 82.2, "DMZ 10.7.43.0/28 (Cloud1)", ha="center", fontsize=12.5, fontweight="bold", color=C_WEB)
ax.text(165, 78.4, "Kali = host Docker (10.7.43.10)", ha="center", fontsize=8.8, color=INK,
        family="DejaVu Sans Mono")
box(144, 59, 42, 14, "web-caja", ["Sistema de Caja · 10.7.43.2", "nginx :80 · SSH :22"], C_OK, fs=8.8, tfs=11)
box(144, 40, 42, 14, "web-inventario", ["Sist. de Inventario · 10.7.43.3", "nginx :80 · SSH :22"], C_WEB, fs=8.8, tfs=11)
box(144, 21, 42, 14, "db-server", ["Base de datos · 10.7.43.4", "MariaDB :3306 · SSH :22"], C_DB, fs=8.8, tfs=11)

# Links
link((66, 80.5), (66, 86.2), "port1", off=(5, 0))
link((38.5, 68), (47.5, 68), "e0/0 ↔ port2", off=(0, 2.4), fs=7.8)
link((84.5, 68), (95.5, 68), "port3 ↔ e0/0", off=(0, 2.4), fs=7.8)
link((130.5, 68), (139.5, 68), "e0/1", off=(0, 2.2))
link((15, 55.5), (15, 43.5), "e0/1", off=(4, 0))
link((27, 55.5), (46, 43.5), "e0/2", off=(4.5, 0.5))

# Policy legend
ax.add_patch(FancyBboxPatch((2, 1.5), 128, 16, boxstyle="round,pad=0.4,rounding_size=1.5",
                            linewidth=1.2, edgecolor=C_MG, facecolor="#f9fafb", zorder=1))
rows = [
    (C_USR, "VLAN 10 → DMZ", "solo web (HTTP/HTTPS) · Web Filter bloquea Inventario con aviso"),
    (C_ADM, "VLAN 20 → DMZ", "web + SSH + PING (única VLAN con SSH a los servidores)"),
    (C_WEB, "DMZ → Internet", "solo endpoints de actualización (Debian, Kali, Docker Hub) · NAT"),
    (C_FGT, "DMZ → LAN", "sin política: Implicit Deny (registrado) · no hay fuga hacia la LAN"),
]
for i, (c, a, b) in enumerate(rows):
    y = 14.6 - i*3.6
    ax.text(4.5, y, a, fontsize=9.4, fontweight="bold", color=c, va="center")
    ax.text(24, y, b, fontsize=8.9, color=INK, va="center")

plt.savefig("topologia_p3_infra1.png", bbox_inches="tight", facecolor="white")
print("ok")
